const express = require('express');
const bodyParser = require('body-parser');
const photoRoutes = require('./routes/photoRoutes');

const app = express();
const PORT = 5000;

app.use(bodyParser.json());
// Middleware to parse JSON
app.use(express.json());

app.use('/api/photos', photoRoutes);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
