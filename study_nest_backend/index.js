const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Increase payload limit to 10MB

// Ensure all errors return JSON, not HTML
app.use((err, req, res, next) => {
  console.error('Server error:', err.message, err.stack);
  res.status(500).json({ error: 'Internal server error', details: err.message });
});

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/studynest').then(() => {
  console.log('Connected to MongoDB');
}).catch(err => {
  console.error('Failed to connect to MongoDB:', err);
  process.exit(1);
});

// Define Schemas
const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true, enum: ['student', 'teacher', 'admin'] },
  rollno: { type: String, required: true },
});

const pageSchema = new mongoose.Schema({
  name: { type: String, required: true },
  semester: { type: Number, required: true },
});

const fileSchema = new mongoose.Schema({
  pageName: { type: String, required: true },
  name: { type: String, required: true },
  fileData: { type: String, required: true }, // Store base64-encoded file
  contentType: { type: String, required: true }, // e.g., 'application/pdf'
  uploadedAt: { type: Date, default: Date.now },
});

const careerPathSchema = new mongoose.Schema({
  careerPath: { type: String, required: true, unique: true },
  pdfData: { type: String, required: true }, // Store base64-encoded PDF
  contentType: { type: String, required: true }, // e.g., 'application/pdf'
  uploadedBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

// Define Models
const User = mongoose.model('User', userSchema, 'users');
const Page = mongoose.model('Page', pageSchema);
const File = mongoose.model('File', fileSchema);
const CareerPath = mongoose.model('CareerPath', careerPathSchema);

// Middleware to check if user is a teacher
const isTeacher = async (req, res, next) => {
  const username = req.headers['x-username'];
  if (!username) {
    console.error('Validation failed: Username required in headers');
    return res.status(401).json({ error: 'Username required in headers' });
  }
  try {
    const user = await User.findOne({ username });
    if (!user) {
      console.error('User not found:', username);
      return res.status(401).json({ error: 'User not found' });
    }
    if (user.role !== 'teacher') {
      console.error('User not authorized:', username, user.role);
      return res.status(403).json({ error: 'Only teachers can perform this action' });
    }
    req.user = user;
    next();
  } catch (err) {
    console.error('Error in isTeacher middleware:', err);
    res.status(500).json({ error: 'Server error', details: err.message });
  }
};

// Routes for pages
app.get('/pages', async (req, res) => {
  try {
    const pages = await Page.find();
    console.log('Fetched pages:', pages);
    res.json(pages);
  } catch (err) {
    console.error('Error fetching pages:', err);
    res.status(500).json({ error: 'Failed to load subjects', details: err.message });
  }
});

app.post('/pages', isTeacher, async (req, res) => {
  const { name, semester } = req.body;
  try {
    console.log('Creating page:', name, semester);
    const page = new Page({ name, semester });
    await page.save();
    console.log('Page created:', page);
    res.status(201).json({ message: 'Page created' });
  } catch (err) {
    console.error('Error creating page:', err);
    res.status(500).json({ error: 'Failed to create page', details: err.message });
  }
});

app.delete('/pages/:pageName', isTeacher, async (req, res) => {
  const pageName = req.params.pageName;
  if (!pageName || pageName.trim() === '') {
    console.error('Validation failed: Page name is required');
    return res.status(400).json({ error: 'Page name is required' });
  }
  try {
    console.log('Deleting page:', pageName);
    const page = await Page.findOneAndDelete({ name: pageName });
    if (!page) {
      console.error('Page not found:', pageName);
      return res.status(404).json({ error: 'Page not found' });
    }
    console.log('Deleting files for page:', pageName);
    await File.deleteMany({ pageName });
    console.log('Page deleted:', pageName);
    res.json({ message: 'Page deleted' });
  } catch (err) {
    console.error('Error deleting page:', err);
    res.status(500).json({ error: 'Failed to delete page', details: err.message });
  }
});

// Routes for files
app.post('/pages/:pageName/files', isTeacher, async (req, res) => {
  const pageName = req.params.pageName;
  const { name, fileData, contentType } = req.body;
  console.log('Upload request:', { pageName, name, contentType, fileDataLength: fileData ? fileData.length : 0 });

  if (!pageName || pageName.trim() === '') {
    console.error('Validation failed: Page name is required');
    return res.status(400).json({ error: 'Page name is required' });
  }
  if (!name || !fileData || !contentType) {
    console.error('Validation failed: Missing required fields', { name, fileData: !!fileData, contentType });
    return res.status(400).json({ error: 'File name, data, and content type are required' });
  }
  // Validate file size (MongoDB document limit is 16MB, base64 increases size by ~33%)
  const maxBase64Size = 12 * 1024 * 1024; // 12MB to stay under 16MB after overhead
  if (fileData.length > maxBase64Size) {
    console.error('Validation failed: File too large', { fileDataLength: fileData.length, maxBase64Size });
    return res.status(400).json({ error: `File too large. Maximum size is ${maxBase64Size / (1024 * 1024)}MB.` });
  }
  try {
    console.log('Fetching page:', pageName);
    const page = await Page.findOne({ name: pageName });
    if (!page) {
      console.error('Page not found:', pageName);
      return res.status(404).json({ error: 'Page not found' });
    }
    console.log('Checking for existing file:', name);
    const existingFile = await File.findOne({ pageName, name });
    if (existingFile) {
      console.error('File already exists:', name);
      return res.status(400).json({ error: 'File with this name already exists' });
    }
    console.log('Saving new file:', name);
    const file = new File({
      pageName,
      name,
      fileData,
      contentType,
    });
    await file.save();
    console.log('File uploaded and saved to MongoDB:', file);
    res.status(201).json({ message: 'File uploaded' });
  } catch (err) {
    console.error('Error uploading file:', err.message, err.stack);
    res.status(500).json({ error: 'Failed to upload file', details: err.message });
  }
});

app.get('/pages/:pageName/files', async (req, res) => {
  const pageName = req.params.pageName;
  if (!pageName || pageName.trim() === '') {
    console.error('Validation failed: Page name is required');
    return res.status(400).json({ error: 'Page name is required' });
  }
  try {
    console.log('Fetching page:', pageName);
    const page = await Page.findOne({ name: pageName });
    if (!page) {
      console.error('Page not found:', pageName);
      return res.status(404).json({ error: 'Page not found' });
    }
    console.log('Fetching files for page:', pageName);
    const files = await File.find({ pageName });
    // Format the response to include fileData and contentType
    const formattedFiles = files.map(file => ({
      name: file.name,
      fileData: file.fileData,
      contentType: file.contentType,
    }));
    console.log('Fetched files for page', pageName, ':', formattedFiles.length);
    res.json(formattedFiles);
  } catch (err) {
    console.error('Error fetching files:', err);
    res.status(500).json({ error: 'Failed to load files', details: err.message });
  }
});

// Routes for career paths
app.post('/career-paths', isTeacher, async (req, res) => {
  const { careerPath, pdfData, contentType } = req.body;
  console.log('Career path upload request:', { careerPath, contentType, pdfDataLength: pdfData ? pdfData.length : 0 });

  if (!careerPath || !pdfData || !contentType) {
    console.error('Validation failed: Missing required fields', { careerPath, pdfData: !!pdfData, contentType });
    return res.status(400).json({ error: 'Career path, PDF data, and content type are required' });
  }
  // Validate file size (MongoDB document limit is 16MB, base64 increases size by ~33%)
  const maxBase64Size = 12 * 1024 * 1024; // 12MB to stay under 16MB after overhead
  if (pdfData.length > maxBase64Size) {
    console.error('Validation failed: PDF too large', { pdfDataLength: pdfData.length, maxBase64Size });
    return res.status(400).json({ error: `PDF too large. Maximum size is ${maxBase64Size / (1024 * 1024)}MB.` });
  }
  try {
    console.log('Checking for existing career path:', careerPath);
    const existingCareerPath = await CareerPath.findOne({ careerPath });
    if (existingCareerPath) {
      console.error('Career path already exists:', careerPath);
      return res.status(400).json({ error: 'Career path already exists' });
    }
    console.log('Saving new career path:', careerPath);
    const newCareerPath = new CareerPath({
      careerPath,
      pdfData,
      contentType,
      uploadedBy: req.user.username,
    });
    await newCareerPath.save();
    console.log('Career path PDF uploaded and saved to MongoDB:', newCareerPath);
    res.status(201).json({ message: 'Career path PDF uploaded' });
  } catch (err) {
    console.error('Error uploading career path PDF:', err.message, err.stack);
    res.status(500).json({ error: 'Failed to upload career path PDF', details: err.message });
  }
});

app.get('/career-paths', async (req, res) => {
  try {
    console.log('Fetching career paths');
    const careerPaths = await CareerPath.find().select('careerPath pdfData contentType');
    console.log('Fetched career paths:', careerPaths.length);
    res.json(careerPaths);
  } catch (err) {
    console.error('Error fetching career paths:', err);
    res.status(500).json({ error: 'Failed to load career paths', details: err.message });
  }
});

// User registration
app.post('/register', async (req, res) => {
  const { username, password, role, rollno } = req.body;
  if (!username || !password || !role || !rollno) {
    console.error('Validation failed: Missing required fields', { username, role, rollno });
    return res.status(400).json({ error: 'Username, password, role, and rollno are required' });
  }
  if (!['student', 'teacher'].includes(role)) {
    console.error('Validation failed: Invalid role', role);
    return res.status(400).json({ error: 'Role must be "student" or "teacher"' });
  }
  try {
    console.log('Checking for existing user:', username);
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      console.error('User already exists:', username);
      return res.status(400).json({ error: 'Username already exists' });
    }
    console.log('Hashing password for user:', username);
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword, role, rollno });
    await user.save();
    console.log('User registered:', username);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error('Error registering user:', err);
    res.status(500).json({ error: 'Failed to register user', details: err.message });
  }
});

// User login
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    console.error('Validation failed: Username and password are required');
    return res.status(400).json({ error: 'Username and password are required' });
  }
  try {
    console.log('Fetching user:', username);
    const user = await User.findOne({ username });
    if (!user) {
      console.error('User not found:', username);
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    console.log('Comparing password for user:', username);
    let isMatch = false;
    if (user.password.startsWith('$2b$')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = password === user.password;
    }
    if (!isMatch) {
      console.error('Invalid password for user:', username);
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    console.log('User logged in:', username);
    res.json({ message: 'Login successful', role: user.role });
  } catch (err) {
    console.error('Error logging in:', err);
    res.status(500).json({ error: 'Failed to login', details: err.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});