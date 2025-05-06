const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function createAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/studynest');
    console.log('MongoDB connected');

    // Define the user schema (same as in index.js)
    const userSchema = new mongoose.Schema({
      username: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      role: { type: String, required: true, enum: ['student', 'teacher', 'admin'] },
      rollno: { type: String, required: true },
    });

    const User = mongoose.model('User', userSchema, 'users');

    // Check if admin already exists
    const existingAdmin = await User.findOne({ username: 'admin' });
    if (existingAdmin) {
      console.log('Admin user already exists');
      return;
    }

    // Create admin user
    const admin = new User({
      username: 'admin',
      password: await bcrypt.hash('adminpassword', 10),
      role: 'admin',
      rollno: 'admin',
    });

    await admin.save();
    console.log('Admin user created successfully');
  } catch (err) {
    console.error('Error creating admin user:', err);
  } finally {
    await mongoose.connection.close();
  }
}

createAdmin().catch(console.dir);