const fs = require("fs");
async function files() {
  fs.readdir(".", async (err, files) => {
    if (err) {
      console.error(err);
      return;
    }

    for (const file of files) {
      console.log(file);
      await delay(500); // Adjusted delay to milliseconds
    }
  });
}

function delay(time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
function files2() {
  fs.readdir(".", async (err, files) => {
    let string = "";
    files.forEach((file) => {
      string = string + file + "\n";
    });
    console.log(string);
  });
}

function main() {
  if (process.argv.length > 3) {
    throw new Error("Too many arguments");
  } else if (process.argv.length === 3) {
    if (process.argv[2] === "--slow") {
      files();
    } else if (process.argv[2] == "--fast") {
      files2();
    } else {
      throw new Error("Command not found");
    }
  } else {
    files2();
  }
}
main();
