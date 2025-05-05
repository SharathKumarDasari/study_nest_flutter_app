// const bcrypt = require('bcryptjs');

// async function createUser(collection, rollno, password, role) {
//     const hashedPassword = await bcrypt.hash(password, 10);
//     const user = { rollno, password: hashedPassword, role };
//     await collection.insertOne(user);
// }

// async function findUser(collection, rollno) {
//     return await collection.findOne({ rollno });
// }

// module.exports = { createUser, findUser };

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Define the user schema
const userSchema = new mongoose.Schema({
  rollno: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true },
  adminUsername: String, // Add this field for admin users
  adminPassword: String, // Add this field for admin users
});

const User = mongoose.model('User', userSchema);

async function createUser(rollno, password, role) {
  const hashedPassword = await bcrypt.hash(password, 10);
  const user = new User({ rollno, password: hashedPassword, role });
  await user.save();
}

async function findUser(rollno) {
  return await User.findOne({ rollno });
}

async function findAdmin(adminUsername) {
  return await User.findOne({ adminUsername });
}

module.exports = { User, createUser, findUser, findAdmin };