const fs = require('fs');
const { exec } = require('child_process');

// Check if node_modules directory exists
if (fs.existsSync('node_modules')) {
    console.log('node_modules exists. Running: node scripts/inject-annotation.js');
    exec('node scripts/inject-annotation.js', (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing script: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Script error: ${stderr}`);
            return;
        }
        console.log(`Script output: ${stdout}`);
    });
} else {
    console.log('node_modules does not exist. Running: yarn node scripts/inject-annotation.js');
    exec('yarn node scripts/inject-annotation.js', (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing script: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Script error: ${stderr}`);
            return;
        }
        console.log(`Script output: ${stdout}`);
    });
} 