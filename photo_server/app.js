
const cors = require('cors');
const bodyParser = require('body-parser');
const express = require('express');
const path = require('path');
const routes = require('./routes/albums');
const port = 5000

//create the Express app
var app = express();
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use('/models', express.static(path.join(__dirname, '../models')));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Set up routes
app.use('/api', routes);


app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});

// app.use(cors({ origin: '*' }));
// app.use(express.static('public'));
// app.use(express.json());


// // Create MongoDB connection
// const conn = mongoose.createConnection(CONNECTION_STRING, {
//     useNewUrlParser: true,
//     useUnifiedTopology: true,
//     serverSelectionTimeoutMS: 30000 // 30 seconds

// });


// // Initialize GridFS
// let gfs;
// conn.once('open', () => {
//     gfs = Grid(conn.db, mongoose.mongo);
//     gfs.collection('photos');
//     console.log('Connected to MongoDB and GridFS initialized');
// });

// // Create storage engine
// const storage = new GridFsStorage({
//     url: CONNECTION_STRING,
//     file: (req, file) => {
//       return new Promise((resolve, reject) => {
//         crypto.randomBytes(16, (err, buf) => {
//           if (err) {
//             return reject(err);
//           }
//           const filename = buf.toString('hex') + path.extname(file.originalname);
//           const fileInfo = {
//             filename: filename,
//             bucketName: 'photos' // Collection name in MongoDB
//           };
//           resolve(fileInfo);
//         });
//       });
//     }
//   });


// const conn = mongoose.createConnection(CONNECTION_STRING);
// conn.on('error', (err) => {
//     console.error('MongoDB connection error:', err);
// });

// conn.once('open', () => {
//     console.log('Connected to MongoDB successfully!');
//     gfs = Grid(conn.db, mongoose.mongo);
//     gfs.collection('photos');
// });


// const storage = new GridFsStorage({
//   url: CONNECTION_STRING,
//   file: (req, file) => {
//     return new Promise((resolve, reject) => {
//       crypto.randomBytes(16, (err, buf) => {
//         if (err) {
//           return reject(err);
//         }
//         const filename = buf.toString('hex') + path.extname(file.originalname);
//         const fileInfo = {
//           filename: filename,
//           bucketName: 'photos'
//         };
//         resolve(fileInfo);
//       });
//     });
//   }
// });

//connect to MongoDB
// mongoose.connect(CONNECTION_STRING, {
//     useNewUrlParser: true,
//     useUnifiedTopology: true
// }).then(() => {
//     console.log("Connected to MongoDB");
// }).catch((error) => {
//     console.log("Error connecting to MongoDB:", error);
// });


// mongoose.connect(CONNECTION_STRING, { useNewUrlParser: true, useUnifiedTopology: true });

// const conn = mongoose.connection;

// conn.once('open', () => {
//     const gfs = Grid(conn.db, mongoose.mongo);
//     gfs.collection('photos');
    
//     gfs.files.find().toArray((err, files) => {
//         if (err) {
//             console.error('Error fetching files:', err);
//             return;
//         }

//         if (!files || files.length === 0) {
//             console.log('No files found');
//         } else {
//             console.log('Files found:', files);
//         }
//     });
// });


