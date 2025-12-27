require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const { OAuth2Client } = require('google-auth-library');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.set('trust proxy', 1);
const port = process.env.API_PORT || 11002;

// ============================================
// DATABASE CONNECTION
// ============================================
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'sheepfarm_db',
  user: process.env.DB_USER || 'sheepfarm_user',
  password: process.env.DB_PASSWORD || '8o19223242',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// ============================================
// GOOGLE AUTH CONFIGURATION
// ============================================
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '954066591732-pghev34d8h5lkp9sdbu8qoasda33a35q.apps.googleusercontent.com';
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

// ============================================
// SECURITY MIDDLEWARE
// ============================================
app.use(helmet());
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'Access token required' });
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

// ============================================
// HEALTH CHECK ENDPOINTS
// ============================================
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    service: 'Goat Farm Manager API',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.get('/api/db-health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as timestamp, version() as pg_version');
    res.json({
      status: 'OK',
      database: 'Connected',
      timestamp: result.rows[0].timestamp,
      version: result.rows[0].pg_version
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      database: 'Connection failed',
      error: error.message
    });
  }
});

// ============================================
// AUTHENTICATION ENDPOINTS
// ============================================

// User registration
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, email, full_name } = req.body;
    
    if (!username || !password || !email) {
      return res.status(400).json({ error: 'Username, password, and email are required' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const result = await pool.query(
      'INSERT INTO users (username, password_hash, email, full_name, last_login) VALUES ($1, $2, $3, $4, NOW()) RETURNING id, username, email, full_name, created_at',
      [username, hashedPassword, email, full_name]
    );
    
    // Create default farm settings for new user
    await pool.query(
      'INSERT INTO farm_settings (farm_name, owner_name, email, user_id) VALUES ($1, $2, $3, $4)',
      [username + "'s Farm", full_name, email, result.rows[0].id]
    );
    
    res.status(201).json({
      message: 'User registered successfully',
      user: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Username or email already exists' });
    }
    res.status(500).json({ error: 'Registration failed: ' + error.message });
  }
});

// User login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    const result = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      [username]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Update last login
    await pool.query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);
    
    const token = jwt.sign(
      { userId: user.id, username: user.username, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        full_name: user.full_name
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed: ' + error.message });
  }
});

// Token validation
app.get('/api/auth/validate', authenticateToken, async (req, res) => {
  res.json({ valid: true, user: req.user });
});

// Google Login
app.post('/api/auth/google', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'ID Token is required' });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    const { email, name, sub, picture } = payload;

    // Check if user exists
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    
    let user;

    if (userResult.rows.length > 0) {
      user = userResult.rows[0];
      
      // Update Google ID and avatar if not set
      if (!user.google_id) {
        await pool.query('UPDATE users SET google_id = $1, avatar_url = $2, last_login = NOW() WHERE id = $3', 
          [sub, picture, user.id]);
      } else {
        await pool.query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);
      }
    } else {
      // Create new user
      const baseUsername = email.split('@')[0];
      const finalUsername = `${baseUsername}_${Math.floor(Math.random() * 1000)}`;

      const newUserResult = await pool.query(
        `INSERT INTO users (username, email, full_name, google_id, avatar_url, last_login) 
         VALUES ($1, $2, $3, $4, $5, NOW()) 
         RETURNING id, username, email, full_name`,
        [finalUsername, email, name, sub, picture]
      );
      user = newUserResult.rows[0];
      
      // Create default farm settings
      await pool.query(
        'INSERT INTO farm_settings (farm_name, owner_name, email, user_id) VALUES ($1, $2, $3, $4)',
        [user.username + "'s Farm", user.full_name, user.email, user.id]
      );
    }

    const token = jwt.sign(
      { userId: user.id, username: user.username, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        avatar_url: picture
      }
    });

  } catch (error) {
    console.error('Google Auth Error:', error);
    res.status(401).json({ error: 'Invalid Google Token', details: error.message });
  }
});

// ============================================
// GOAT MANAGEMENT ENDPOINTS
// ============================================

// Get all goats for user
app.get('/api/goats', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM goats WHERE user_id = $1 AND is_active = true ORDER BY created_at DESC',
      [req.user.userId]
    );
    res.json({ goats: result.rows });
  } catch (error) {
    console.error('Error fetching goats:', error);
    res.status(500).json({ error: 'Failed to fetch goats' });
  }
});

// Get single goat
app.get('/api/goats/:id', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM goats WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Goat not found' });
    }
    
    // Get weight history
    const weightResult = await pool.query(
      'SELECT * FROM weight_history WHERE goat_id = $1 ORDER BY measurement_date DESC',
      [req.params.id]
    );
    
    // Get kidding history
    const kiddingResult = await pool.query(
      'SELECT * FROM kidding_history WHERE goat_id = $1 ORDER BY kidding_date DESC',
      [req.params.id]
    );
    
    res.json({
      goat: result.rows[0],
      weightHistory: weightResult.rows,
      kiddingHistory: kiddingResult.rows
    });
  } catch (error) {
    console.error('Error fetching goat:', error);
    res.status(500).json({ error: 'Failed to fetch goat' });
  }
});

// Create new goat
app.post('/api/goats', authenticateToken, async (req, res) => {
  try {
    const goatData = req.body;
    const userId = req.user.userId;
    
    // Check if tag number already exists for this user
    const existingGoat = await pool.query(
      'SELECT id FROM goats WHERE tag_no = $1 AND user_id = $2',
      [goatData.tagNo, userId]
    );
    
    if (existingGoat.rows.length > 0) {
      return res.status(400).json({ error: 'Tag number already exists' });
    }
    
    const result = await pool.query(
      `INSERT INTO goats (
        tag_no, name, breed, gender, goat_stage, date_of_birth, date_of_entry,
        weight, goat_group, obtained_from, mother_tag, father_tag, notes,
        photo_path, breeding_status, breeding_date, breeding_partner, kidding_due_date, user_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
      RETURNING *`,
      [
        goatData.tagNo, goatData.name, goatData.breed, goatData.gender,
        goatData.goatStage, goatData.dateOfBirth, goatData.dateOfEntry,
        goatData.weight, goatData.group, goatData.obtained, goatData.motherTag,
        goatData.fatherTag, goatData.notes, goatData.photoPath,
        goatData.breedingStatus || 'Not Bred', goatData.breedingDate,
        goatData.breedingPartner, goatData.kiddingDueDate, userId
      ]
    );
    
    res.status(201).json({ goat: result.rows[0], message: 'Goat created successfully' });
  } catch (error) {
    console.error('Error creating goat:', error);
    res.status(500).json({ error: 'Failed to create goat: ' + error.message });
  }
});

// Update goat
app.put('/api/goats/:id', authenticateToken, async (req, res) => {
  try {
    const goatId = req.params.id;
    const goatData = req.body;
    const userId = req.user.userId;
    
    // Check if goat belongs to user
    const checkResult = await pool.query(
      'SELECT id FROM goats WHERE id = $1 AND user_id = $2',
      [goatId, userId]
    );
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Goat not found' });
    }
    
    const result = await pool.query(
      `UPDATE goats SET
        name = COALESCE($1, name),
        breed = COALESCE($2, breed),
        gender = COALESCE($3, gender),
        goat_stage = COALESCE($4, goat_stage),
        date_of_birth = COALESCE($5, date_of_birth),
        date_of_entry = COALESCE($6, date_of_entry),
        weight = COALESCE($7, weight),
        goat_group = COALESCE($8, goat_group),
        obtained_from = COALESCE($9, obtained_from),
        mother_tag = COALESCE($10, mother_tag),
        father_tag = COALESCE($11, father_tag),
        notes = COALESCE($12, notes),
        photo_path = COALESCE($13, photo_path),
        breeding_status = COALESCE($14, breeding_status),
        breeding_date = COALESCE($15, breeding_date),
        breeding_partner = COALESCE($16, breeding_partner),
        kidding_due_date = COALESCE($17, kidding_due_date)
      WHERE id = $18 AND user_id = $19
      RETURNING *`,
      [
        goatData.name, goatData.breed, goatData.gender, goatData.goatStage,
        goatData.dateOfBirth, goatData.dateOfEntry, goatData.weight,
        goatData.group, goatData.obtained, goatData.motherTag, goatData.fatherTag,
        goatData.notes, goatData.photoPath, goatData.breedingStatus,
        goatData.breedingDate, goatData.breedingPartner, goatData.kiddingDueDate,
        goatId, userId
      ]
    );
    
    res.json({ goat: result.rows[0], message: 'Goat updated successfully' });
  } catch (error) {
    console.error('Error updating goat:', error);
    res.status(500).json({ error: 'Failed to update goat: ' + error.message });
  }
});

// Delete goat (soft delete)
app.delete('/api/goats/:id', authenticateToken, async (req, res) => {
  try {
    const goatId = req.params.id;
    const userId = req.user.userId;
    
    const result = await pool.query(
      'UPDATE goats SET is_active = false WHERE id = $1 AND user_id = $2 RETURNING *',
      [goatId, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Goat not found' });
    }
    
    res.json({ message: 'Goat deleted successfully' });
  } catch (error) {
    console.error('Error deleting goat:', error);
    res.status(500).json({ error: 'Failed to delete goat' });
  }
});

// Bulk sync goats with duplicate prevention
app.post('/api/sync/goats', authenticateToken, async (req, res) => {
  try {
    const goatsData = req.body.goats || [];
    const userId = req.user.userId;
    
    let created = 0;
    let updated = 0;
    const errors = [];
    const syncedGoats = [];

    for (const goatData of goatsData) {
      try {
        // Check if goat exists by tag_no (not tagNo)
        const existingResult = await pool.query(
          'SELECT id FROM goats WHERE tag_no = $1 AND user_id = $2',
          [goatData.tagNo, userId]
        );
        
        if (existingResult.rows.length > 0) {
          // Update existing goat - use tagNo as tag_no
          const goatId = existingResult.rows[0].id;
          
          await pool.query(
            `UPDATE goats SET
              name = $1, breed = $2, gender = $3, goat_stage = $4,
              date_of_birth = $5, date_of_entry = $6, weight = $7,
              goat_group = $8, obtained_from = $9, mother_tag = $10,
              father_tag = $11, notes = $12, photo_path = $13,
              breeding_status = $14, breeding_date = $15,
              breeding_partner = $16, kidding_due_date = $17,
              is_active = true, updated_at = CURRENT_TIMESTAMP
            WHERE id = $18 AND user_id = $19`,
            [
              goatData.name, goatData.breed, goatData.gender, goatData.goatStage,
              goatData.dateOfBirth, goatData.dateOfEntry, goatData.weight,
              goatData.group, goatData.obtained, goatData.motherTag,
              goatData.fatherTag, goatData.notes, goatData.photoPath,
              goatData.breedingStatus, goatData.breedingDate,
              goatData.breedingPartner, goatData.kiddingDueDate,
              goatId, userId
            ]
          );
          
          // Get updated goat
          const updatedGoat = await pool.query(
            'SELECT * FROM goats WHERE id = $1',
            [goatId]
          );
          
          syncedGoats.push(updatedGoat.rows[0]);
          updated++;
        } else {
          // Create new goat - map tagNo to tag_no
          const result = await pool.query(
            `INSERT INTO goats (
              tag_no, name, breed, gender, goat_stage, date_of_birth, date_of_entry,
              weight, goat_group, obtained_from, mother_tag, father_tag, notes,
              photo_path, breeding_status, breeding_date, breeding_partner,
              kidding_due_date, user_id
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
            RETURNING *`,
            [
              goatData.tagNo, goatData.name, goatData.breed, goatData.gender,
              goatData.goatStage, goatData.dateOfBirth, goatData.dateOfEntry,
              goatData.weight, goatData.group, goatData.obtained, goatData.motherTag,
              goatData.fatherTag, goatData.notes, goatData.photoPath,
              goatData.breedingStatus || 'Not Bred', goatData.breedingDate,
              goatData.breedingPartner, goatData.kiddingDueDate, userId
            ]
          );
          
          syncedGoats.push(result.rows[0]);
          created++;
        }
      } catch (error) {
            console.error(`Error syncing goat ${goatData.tagNo}:`, error);
            errors.push(`Goat ${goatData.tagNo || 'unknown'}: ${error.message}`);
        }
    }

      res.json({
      message: 'Goats sync completed',
      created,
      updated,
      errors: errors.length > 0 ? errors : null,
      goats: syncedGoats
    });
  } catch (error) {
    console.error('Error in sync/goats:', error);
    res.status(500).json({ 
      error: 'Failed to sync goats',
      details: error.message 
    });
  }
});

// ============================================
// WEIGHT HISTORY ENDPOINTS
// ============================================

// Add weight record
app.post('/api/goats/:id/weight', authenticateToken, async (req, res) => {
  try {
    const goatId = req.params.id;
    const { weight, measurement_date, notes } = req.body;
    const userId = req.user.userId;
    
    // Verify goat belongs to user
    const goatCheck = await pool.query(
      'SELECT id FROM goats WHERE id = $1 AND user_id = $2',
      [goatId, userId]
    );
    
    if (goatCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Goat not found' });
    }
    
    const result = await pool.query(
      `INSERT INTO weight_history (goat_id, weight, measurement_date, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [goatId, weight, measurement_date, notes]
    );
    
    // Update goat's current weight
    await pool.query(
      'UPDATE goats SET weight = $1 WHERE id = $2',
      [weight, goatId]
    );
    
    res.status(201).json({ weightRecord: result.rows[0] });
  } catch (error) {
    console.error('Error adding weight:', error);
    res.status(500).json({ error: 'Failed to add weight record' });
  }
});

// ============================================
// KIDDING HISTORY ENDPOINTS
// ============================================

// Add kidding record
app.post('/api/goats/:id/kidding', authenticateToken, async (req, res) => {
  try {
    const goatId = req.params.id;
    const { kidding_date, number_of_kids, kids_gender, kids_weight, notes } = req.body;
    const userId = req.user.userId;
    
    // Verify goat belongs to user
    const goatCheck = await pool.query(
      'SELECT id FROM goats WHERE id = $1 AND user_id = $2',
      [goatId, userId]
    );
    
    if (goatCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Goat not found' });
    }
    
    const result = await pool.query(
      `INSERT INTO kidding_history (goat_id, kidding_date, number_of_kids, kids_gender, kids_weight, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [goatId, kidding_date, number_of_kids, kids_gender, kids_weight, notes]
    );
    
    res.status(201).json({ kiddingRecord: result.rows[0] });
  } catch (error) {
    console.error('Error adding kidding record:', error);
    res.status(500).json({ error: 'Failed to add kidding record' });
  }
});

// ============================================
// EVENTS ENDPOINTS
// ============================================

// Get all events for user
app.get('/api/events', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM events WHERE user_id = $1 ORDER BY event_date DESC, event_time DESC',
      [req.user.userId]
    );
    res.json({ events: result.rows });
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({ error: 'Failed to fetch events' });
  }
});

// Create event
app.post('/api/events', authenticateToken, async (req, res) => {
  try {
    const eventData = req.body;
    const userId = req.user.userId;
    
    const result = await pool.query(
      `INSERT INTO events (
        title, description, event_type, event_date, event_time,
        goats_involved, location, notes, user_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        eventData.title, eventData.description, eventData.event_type,
        eventData.event_date, eventData.event_time, eventData.goats_involved,
        eventData.location, eventData.notes, userId
      ]
    );
    
    res.status(201).json({ event: result.rows[0] });
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({ error: 'Failed to create event' });
  }
});

// Sync events with duplicate prevention
app.post('/api/sync/events', authenticateToken, async (req, res) => {
  try {
    const eventsData = req.body.events || [];
    const userId = req.user.userId;
    
    let created = 0;
    const errors = [];

    for (const eventData of eventsData) {
      try {
        // Check if event already exists (by title, date, and user)
        const existing = await pool.query(
          `SELECT id FROM events 
           WHERE title = $1 AND event_date = $2 AND user_id = $3`,
          [eventData.title, eventData.event_date, userId]
        );
        
        if (existing.rows.length === 0) {
          await pool.query(
            `INSERT INTO events (
              title, description, event_type, event_date, event_time,
              goats_involved, location, notes, user_id
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [
              eventData.title, eventData.description, eventData.event_type,
              eventData.event_date, eventData.event_time, eventData.goats_involved,
              eventData.location, eventData.notes, userId
            ]
          );
          created++;
        }
      } catch (error) {
            errors.push(`Event ${eventData.title}: ${error.message}`);
        }
    }
    
    res.json({
      message: 'Events sync completed',
      created,
      duplicates: eventsData.length - created,
      errors: errors.length > 0 ? errors : null
    });
  } catch (error) {
    console.error('Error in sync/events:', error);
    res.status(500).json({ error: 'Failed to sync events' });
  }
});

// ============================================
// MILK RECORDS ENDPOINTS
// ============================================

// Get all milk records
app.get('/api/milk-records', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT mr.*, g.tag_no, g.name as goat_name 
       FROM milk_records mr
       JOIN goats g ON mr.goat_id = g.id
       WHERE mr.user_id = $1
       ORDER BY mr.milking_date DESC`,
      [req.user.userId]
    );
    res.json({ milk_records: result.rows });
  } catch (error) {
    console.error('Error fetching milk records:', error);
    res.status(500).json({ error: 'Failed to fetch milk records' });
  }
});

// Create milk record
app.post('/api/milk-records', authenticateToken, async (req, res) => {
  try {
    const milkData = req.body;
    const userId = req.user.userId;
    
    const result = await pool.query(
      `INSERT INTO milk_records (goat_id, milking_date, morning_quantity, evening_quantity, notes, user_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        milkData.goat_id, milkData.milking_date, milkData.morning_quantity,
        milkData.evening_quantity, milkData.notes, userId
      ]
    );
    
    res.status(201).json({ milk_record: result.rows[0] });
  } catch (error) {
    console.error('Error creating milk record:', error);
    res.status(500).json({ error: 'Failed to create milk record' });
  }
});

// Sync milk records with duplicate prevention
app.post('/api/sync/milk-records', authenticateToken, async (req, res) => {
  try {
    const milkRecordsData = req.body.milk_records || [];
    const userId = req.user.userId;
    
    let created = 0;
    const errors = [];

    for (const record of milkRecordsData) {
      try {
        // Check if record exists (by goat_id, date, and user)
        const existing = await pool.query(
          `SELECT id FROM milk_records 
           WHERE goat_id = $1 AND milking_date = $2 AND user_id = $3`,
          [record.goat_id, record.milking_date, userId]
        );
        
        if (existing.rows.length === 0) {
          await pool.query(
            `INSERT INTO milk_records (goat_id, milking_date, morning_quantity, evening_quantity, notes, user_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              record.goat_id, record.milking_date, record.morning_quantity,
              record.evening_quantity, record.notes, userId
            ]
          );
          created++;
        }
      } catch (error) {
            errors.push(`Milk record ${record.milking_date}: ${error.message}`);
        }

    }
    
    res.json({
      message: 'Milk records sync completed',
      created,
      duplicates: milkRecordsData.length - created,
      errors: errors.length > 0 ? errors : null
    });
  } catch (error) {
    console.error('Error in sync/milk-records:', error);
    res.status(500).json({ error: 'Failed to sync milk records' });
  }
});

// ============================================
// TRANSACTIONS ENDPOINTS
// ============================================

// Get all incomes
app.get('/api/incomes', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM incomes WHERE user_id = $1 ORDER BY transaction_date DESC',
      [req.user.userId]
    );
    res.json({ incomes: result.rows });
  } catch (error) {
    console.error('Error fetching incomes:', error);
    res.status(500).json({ error: 'Failed to fetch incomes' });
  }
});

// Get all expenses
app.get('/api/expenses', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM expenses WHERE user_id = $1 ORDER BY transaction_date DESC',
      [req.user.userId]
    );
    res.json({ expenses: result.rows });
  } catch (error) {
    console.error('Error fetching expenses:', error);
    res.status(500).json({ error: 'Failed to fetch expenses' });
  }
});

// Sync transactions
app.post('/api/sync/transactions', authenticateToken, async (req, res) => {
  try {
    const incomesData = req.body.incomes || [];
    const expensesData = req.body.expenses || [];
    const userId = req.user.userId;
    
    let incomesCreated = 0;
    let expensesCreated = 0;
    const errors = [];

    // Sync incomes
    for (const income of incomesData) {
      try {
        const existing = await pool.query(
          `SELECT id FROM incomes 
           WHERE income_type = $1 AND amount = $2 AND transaction_date = $3 AND user_id = $4`,
          [income.income_type, income.amount, income.transaction_date, userId]
        );
        
        if (existing.rows.length === 0) {
          await pool.query(
            `INSERT INTO incomes 
             (income_type, amount, description, transaction_date, buyer_name, buyer_contact, notes, user_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              income.income_type,
              income.amount,
              income.description,
              income.transaction_date,
              income.buyer_name,
              income.buyer_contact,
              income.notes,
              userId
            ]
          );
          incomesCreated++;
        }
      } catch (error) {
        errors.push(`Income ${income.income_type}: ${error.message}`);
      }
    }
    
    // Sync expenses
    for (const expense of expensesData) {
      try {
        const existing = await pool.query(
          `SELECT id FROM expenses 
           WHERE expense_type = $1 AND amount = $2 AND transaction_date = $3 AND user_id = $4`,
          [expense.expense_type, expense.amount, expense.transaction_date, userId]
        );
        
        if (existing.rows.length === 0) {
          await pool.query(
            `INSERT INTO expenses 
             (expense_type, amount, description, transaction_date, vendor_name, vendor_contact, notes, user_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              expense.expense_type,
              expense.amount,
              expense.description,
              expense.transaction_date,
              expense.vendor_name,
              expense.vendor_contact,
              expense.notes,
              userId
            ]
          );
          expensesCreated++;
        }
      } catch (error) {
        errors.push(`Expense ${expense.expense_type}: ${error.message}`);
      }
    }
    
    res.json({
      message: 'Transactions sync completed',
      incomesCreated,
      expensesCreated,
      errors: errors.length > 0 ? errors : null
    });
  } catch (error) {
    console.error('Error in sync/transactions:', error);
    res.status(500).json({ error: 'Failed to sync transactions' });
  }
});

// ============================================
// DOWNLOAD ALL DATA
// ============================================

app.get('/api/sync/download-all', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const [goats, events, milkRecords, incomes, expenses] = await Promise.all([
      pool.query('SELECT * FROM goats WHERE user_id = $1 AND is_active = true', [userId]),
      pool.query('SELECT * FROM events WHERE user_id = $1', [userId]),
      pool.query('SELECT * FROM milk_records WHERE user_id = $1', [userId]),
      pool.query('SELECT * FROM incomes WHERE user_id = $1', [userId]),
      pool.query('SELECT * FROM expenses WHERE user_id = $1', [userId])
    ]);
    
    res.json({
      goats: goats.rows,
      events: events.rows,
      milk_records: milkRecords.rows,
      incomes: incomes.rows,
      expenses: expenses.rows
    });
  } catch (error) {
    console.error('Error downloading data:', error);
    res.status(500).json({ error: 'Failed to download data' });
  }
});

// ============================================
// NOTES ENDPOINTS
// ============================================

// Get notes for authenticated user
app.get('/api/notes', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const result = await pool.query(
      'SELECT * FROM notes WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching notes:', error);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
});

// Create new note
app.post('/api/notes', authenticateToken, async (req, res) => {
  try {
    const { title, content, note_type } = req.body;
    const userId = req.user.userId;
    
    const result = await pool.query(
      `INSERT INTO notes (title, content, note_type, user_id, email) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING *`,
      [title, content, note_type || 'General', userId, req.user.email]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating note:', error);
    res.status(500).json({ error: 'Failed to create note' });
  }
});

// ============================================
// FARM SETTINGS ENDPOINTS
// ============================================

// Get farm settings
app.get('/api/farm-settings', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM farm_settings WHERE user_id = $1',
      [req.user.userId]
    );
    
    if (result.rows.length === 0) {
      // Create default settings if not exists
      const defaultResult = await pool.query(
        `INSERT INTO farm_settings (farm_name, owner_name, email, user_id)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [req.user.username + "'s Farm", req.user.username, req.user.email, req.user.userId]
      );
      res.json(defaultResult.rows[0]);
    } else {
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Error fetching farm settings:', error);
    res.status(500).json({ error: 'Failed to fetch farm settings' });
  }
});

// Update farm settings
app.put('/api/farm-settings', authenticateToken, async (req, res) => {
  try {
    const settings = req.body;
    const userId = req.user.userId;
    
    const result = await pool.query(
      `INSERT INTO farm_settings (
        farm_name, farm_location, owner_name, contact_number, email,
        currency, milk_unit, weight_unit, user_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (user_id) DO UPDATE SET
        farm_name = EXCLUDED.farm_name,
        farm_location = EXCLUDED.farm_location,
        owner_name = EXCLUDED.owner_name,
        contact_number = EXCLUDED.contact_number,
        email = EXCLUDED.email,
        currency = EXCLUDED.currency,
        milk_unit = EXCLUDED.milk_unit,
        weight_unit = EXCLUDED.weight_unit,
        updated_at = CURRENT_TIMESTAMP
      RETURNING *`,
      [
        settings.farm_name, settings.farm_location, settings.owner_name,
        settings.contact_number, settings.email, settings.currency,
        settings.milk_unit, settings.weight_unit, userId
      ]
    );
    
    res.json({ settings: result.rows[0], message: 'Farm settings updated successfully' });
  } catch (error) {
    console.error('Error updating farm settings:', error);
    res.status(500).json({ error: 'Failed to update farm settings' });
  }
});

// ============================================
// START SERVER
// ============================================
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Goat Farm Manager API running on port ${port}`);
  console.log(`📊 Database: ${process.env.DB_NAME}`);
  console.log(`🔐 JWT Secret: ${process.env.JWT_SECRET ? 'Set' : 'Not set'}`);
});

// Handle server shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received. Closing server and database pool...');
  await pool.end();
  process.exit(0);
});