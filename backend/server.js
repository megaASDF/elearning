const express = require('express');
const cors = require('cors');
const multer = require('multer');
const csv = require('csv-parser');
const fs = require('fs');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.use(cors());
app.use(express.json());

// Mock DB for duplicate checking
const existingStudents = [
    { username: 'student1', email: 'student1@fit.edu' },
    { username: 'admin', email: 'admin@fit.edu' }
];

// 1. Upload & Preview Endpoint
app.post('/api/students/upload-preview', upload.single('file'), (req, res) => {
    const results = [];
    
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }

    fs.createReadStream(req.file.path)
        .pipe(csv())
        .on('data', (data) => {
            // Basic validation
            if (!data.username || !data.email) return;

            // Check if student already exists
            const isDuplicate = existingStudents.some(
                s => s.username === data.username || s.email === data.email
            );

            results.push({
                username: data.username,
                email: data.email,
                displayName: data.displayName || data.username,
                status: isDuplicate ? 'Duplicate' : 'Valid',
                canImport: !isDuplicate
            });
        })
        .on('end', () => {
            fs.unlinkSync(req.file.path); // Clean up temp file
            res.json(results);
        })
        .on('error', (err) => {
            res.status(500).json({ error: 'Failed to parse CSV' });
        });
});

// 2. Commit Import Endpoint
app.post('/api/students/import', (req, res) => {
    const { students } = req.body;
    
    if (!students || !Array.isArray(students)) {
        return res.status(400).json({ error: 'Invalid data format' });
    }

    console.log('Importing students:', students);
    
    // In a real app, you would insert these into the database here
    students.forEach(s => existingStudents.push(s));
    
    res.json({ 
        success: true, 
        message: `Successfully imported ${students.length} students` 
    });
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));