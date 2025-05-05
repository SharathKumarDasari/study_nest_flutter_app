const express = require('express');
const multer = require('multer');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Ensure all errors return JSON, not HTML
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Connect to MongoDB
mongoose.connect('mongodb://localhost/studynest').then(() => {
  console.log('Connected to MongoDB');
}).catch(err => {
  console.error('Failed to connect to MongoDB:', err);
  process.exit(1);
});

// Define Schemas
const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true, enum: ['student', 'teacher'] },
  rollno: { type: String, required: true },
});

const pageSchema = new mongoose.Schema({
  name: { type: String, required: true },
  semester: { type: Number, required: true },
});

const fileSchema = new mongoose.Schema({
  pageName: { type: String, required: true },
  name: { type: String, required: true },
  path: { type: String, required: true }, // Store the full file path
  uploadedAt: { type: Date, default: Date.now },
});

// Define Models
const User = mongoose.model('User', userSchema, 'users');
const Page = mongoose.model('Page', pageSchema);
const File = mongoose.model('File', fileSchema);

// Set up multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const pageName = req.params.pageName;
    if (!pageName || pageName.trim() === '') {
      return cb(new Error('Page name is required'), null);
    }
    const uploadPath = path.join(__dirname, 'Uploads', pageName);
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  },
});
const upload = multer({ storage });

// Routes for pages
app.get('/pages', async (req, res) => {
  try {
    const pages = await Page.find();
    console.log('Fetched pages:', pages);
    res.json(pages);
  } catch (err) {
    console.error('Error fetching pages:', err);
    res.status(500).json({ error: 'Failed to load subjects' });
  }
});

app.post('/pages', async (req, res) => {
  const { name, semester } = req.body;
  const username = req.headers['x-username'];
  if (!username) {
    return res.status(401).json({ error: 'Username required in headers' });
  }
  if (!name || !semester) {
    return res.status(400).json({ error: 'Name and semester are required' });
  }
  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    if (user.role !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can create subjects' });
    }
    const page = new Page({ name, semester });
    await page.save();
    console.log('Page created:', page);
    res.status(201).json({ message: 'Page created' });
  } catch (err) {
    console.error('Error creating page:', err);
    res.status(500).json({ error: 'Failed to create page' });
  }
});

app.delete('/pages/:pageName', async (req, res) => {
  const pageName = req.params.pageName;
  if (!pageName || pageName.trim() === '') {
    return res.status(400).json({ error: 'Page name is required' });
  }
  const username = req.headers['x-username'];
  if (!username) {
    return res.status(401).json({ error: 'Username required in headers' });
  }
  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    if (user.role !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can delete subjects' });
    }
    const page = await Page.findOneAndDelete({ name: pageName });
    if (!page) {
      return res.status(404).json({ error: 'Page not found' });
    }
    const pageFiles = await File.find({ pageName });
    pageFiles.forEach(file => {
      const filePath = path.join(__dirname, file.path);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    });
    await File.deleteMany({ pageName });
    console.log('Page deleted:', pageName);
    res.json({ message: 'Page deleted' });
  } catch (err) {
    console.error('Error deleting page:', err);
    res.status(500).json({ error: 'Failed to delete page' });
  }
});

// Routes for files
app.post('/pages/:pageName/files', upload.single('file'), async (req, res) => {
  const pageName = req.params.pageName;
  if (!pageName || pageName.trim() === '') {
    return res.status(400).json({ error: 'Page name is required' });
  }
  const username = req.headers['x-username'];
  if (!username) {
    return res.status(401).json({ error: 'Username required in headers' });
  }
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    if (user.role !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can upload files' });
    }
    const page = await Page.findOne({ name: pageName });
    if (!page) {
      return res.status(404).json({ error: 'Page not found' });
    }
    const existingFile = await File.findOne({ pageName, name: req.file.originalname });
    if (existingFile) {
      return res.status(400).json({ error: 'File with this name already exists' });
    }
    const filePath = path.join('Uploads', pageName, req.file.originalname);
    const file = new File({
      pageName,
      name: req.file.originalname,
      path: filePath,
    });
    await file.save();
    console.log('File uploaded and saved to MongoDB:', file);
    res.status(201).json({ message: 'File uploaded' });
  } catch (err) {
    // Delete the uploaded file if saving fails
    const filePath = path.join(__dirname, 'Uploads', pageName, req.file.originalname);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    console.error('Error uploading file:', err);
    res.status(500).json({ error: 'Failed to upload file' });
  }
});

app.get('/pages/:pageName/files', async (req, res) => {
  const pageName = req.params.pageName;
  if (!pageName || pageName.trim() === '') {
    return res.status(400).json({ error: 'Page name is required' });
  }
  try {
    const page = await Page.findOne({ name: pageName });
    if (!page) {
      return res.status(404).json({ error: 'Page not found' });
    }
    const files = await File.find({ pageName });
    // Format the response to match Flutter app expectations
    const formattedFiles = files.map(file => ({
      name: file.name,
    }));
    console.log('Fetched files for page', pageName, ':', formattedFiles);
    res.json(formattedFiles);
  } catch (err) {
    console.error('Error fetching files:', err);
    res.status(500).json({ error: 'Failed to load files' });
  }
});

// User registration
app.post('/register', async (req, res) => {
  const { username, password, role, rollno } = req.body;
  if (!username || !password || !role || !rollno) {
    return res.status(400).json({ error: 'Username, password, role, and rollno are required' });
  }
  if (!['student', 'teacher'].includes(role)) {
    return res.status(400).json({ error: 'Role must be "student" or "teacher"' });
  }
  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ error: 'Username already exists' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword, role, rollno });
    await user.save();
    console.log('User registered:', username);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error('Error registering user:', err);
    res.status(500).json({ error: 'Failed to register user' });
  }
});

// User login
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }
  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    let isMatch = false;
    if (user.password.startsWith('$2b$')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = password === user.password;
    }
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    console.log('User logged in:', username);
    res.json({ message: 'Login successful', role: user.role });
  } catch (err) {
    console.error('Error logging in:', err);
    res.status(500).json({ error: 'Failed to login' });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});