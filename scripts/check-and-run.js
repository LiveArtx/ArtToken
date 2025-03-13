const fs = require('fs');
const { exec, execSync } = require('child_process');

const nodeModulesPath = './node_modules';

// Check if node_modules directory exists
if (!fs.existsSync(nodeModulesPath)) {
    console.log('node_modules does not exist. Running: yarn install');
    try {
        execSync('yarn install', { stdio: 'inherit' });
    } catch (error) {
        console.error('Error installing dependencies:', error);
        process.exit(1);
    }
} else {
    console.log('node_modules already exists. Skipping yarn install.');
}

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