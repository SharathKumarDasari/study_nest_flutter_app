// const { MongoClient } = require('mongodb');
// const bcrypt = require('bcryptjs');

// async function createAdmin() {
//     const uri = "mongodb://localhost:27017/"; // Replace with your MongoDB Atlas connection string
//     const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });

//     try {
//         await client.connect();
//         const database = client.db('studynest');
//         const collection = database.collection('users');

//         const admin = {
//             rollno: "admin",
//             password: bcrypt.hashSync("adminpassword", 10), // Replace with your admin password
//             role: "admin"
//         };

//         const result = await collection.insertOne(admin);
//         console.log(`Admin user created with _id: ${result.insertedId}`);
//     } finally {
//         await client.close();
//     }
// }

// createAdmin().catch(console.dir);


const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function createAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/studynest');
    console.log('MongoDB connected');

    // Define the user schema (same as in User.js)
    const userSchema = new mongoose.Schema({
      rollno: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      role: { type: String, required: true },
      adminUsername: String,
      adminPassword: String,
    });

    const User = mongoose.model('User', userSchema);

    // Create admin user
    const admin = new User({
      rollno: 'admin',
      password: await bcrypt.hash('adminpassword', 10),
      role: 'admin',
      adminUsername: 'admin',
      adminPassword: await bcrypt.hash('adminpassword', 10),
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