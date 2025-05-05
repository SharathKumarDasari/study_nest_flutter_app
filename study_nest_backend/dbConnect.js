// const { MongoClient } = require('mongodb');
// const uri = "mongodb://localhost:27017/"; // Replace with your MongoDB Atlas connection string
// const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });

// async function connectDB() {
//     await client.connect();
//     console.log("Connected to MongoDB");
//     return client.db('studynest').collection('users');
// }

// module.exports = connectDB;

// const mongoose = require('mongoose');

// const connectDB = async () => {
//   try {
//     // Remove deprecated options
//     await mongoose.connect('mongodb://localhost:27017/studynest');
//     console.log('MongoDB connected');
//   } catch (err) {
//     console.error('MongoDB connection error:', err);
//     process.exit(1);
//   }
// };

// module.exports = connectDB;