#!/usr/bin/env node
const fs = require("fs-extra");
const path = require("path");
const projectDir = process.argv[2];

if (!projectDir) {
  console.error("❌ Please specify the project directory:");
  console.log("   npx create-next-styled-app <project-name>");
  console.log();
  console.log("For example:");
  console.log("   npx create-next-styled-app my-next-app");
  process.exit(1);
}

const sourceDir = path.join(__dirname, "..", "template");
const destDir = path.join(process.cwd(), projectDir);

async function createProject() {
  try {
    // Create project directory
    await fs.mkdir(destDir, { recursive: true });

    // Copy template files
    await fs.copy(sourceDir, destDir);

    // Update the package.json name field
    const packageJsonPath = path.join(destDir, "package.json");
    const packageJson = await fs.readJson(packageJsonPath);
    packageJson.name = projectDir;
    await fs.writeJson(packageJsonPath, packageJson, { spaces: 2 });

    console.log(`\n✅ Success! Your project "${projectDir}" has been created.`);
    console.log(
      "You can now navigate to the project directory and get started:"
    );
    console.log(`\n   cd ${projectDir}`);
    console.log("   npm install");
    console.log("   npm run dev");
    console.log("\nHappy coding! ✨");
  } catch (err) {
    console.error("An error occurred:", err);
    process.exit(1);
  }
}

createProject();
