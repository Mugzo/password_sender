function copy() {
    // Button element
    let copyButton = document.getElementById("copyButton")

    // Get the secret link value
    let inputSecretLink = document.getElementById("secretLink");
    const text = inputSecretLink.getAttribute("value");

    navigator.clipboard.writeText(text);
    copyButton.classList.replace('btn-primary', 'btn-success');

    setTimeout(function () {copyButton.classList.replace('btn-success', 'btn-primary');}, 1000);
}

function generatePassword() {
    // Get the Send Password button element
    let sendPasswordBtn = document.getElementById("sendPassword")

    // Get elements values
    let numbers = document.getElementById("numbersCheck").checked;
    let symbols = document.getElementById("symbolsCheck").checked;
    let length = document.getElementById("lengthRange").value;
    
    // Define character sets
    const lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numberChars = '0123456789';
    const symbolChars = '!@#$%^&*()_+[]{}|;:,.<>?';

    // Combine all characters
    if (numbers && symbols) {
        allChars = lowercaseChars + uppercaseChars + numberChars + symbolChars;
    } else if (numbers) {
        allChars = lowercaseChars + uppercaseChars + numberChars;
    } else if (symbols) {
        allChars = lowercaseChars + uppercaseChars + symbolChars;
    } else {
        allChars = lowercaseChars + uppercaseChars;
    }

    let password = '';

    // Ensure the password includes at least one character from each set
    // password += getRandomChar(lowercaseChars);
    // password += getRandomChar(uppercaseChars);
    // password += getRandomChar(numberChars);
    // password += getRandomChar(symbolChars);

    for (let i = password.length; i < length; i++) {
        password += getRandomChar(allChars);
    }

    //Shuffle the password characters
    password = shuffleString(password);

    // Write the generated password in the textarea
    document.getElementById("passwordFormInput").value = password;

    // Update the characters count
    document.getElementById('passwordCounter').innerHTML = `${password.length} / 64`

    // Enable the Send Password button
    sendPasswordBtn.disabled = false

    // Helper function to get a random character from a string
    function getRandomChar(charSet) {
        const randomIndex = Math.floor(Math.random() * charSet.length);
        return charSet.charAt(randomIndex);
    }

    // Helper function to shuffle a string
    function shuffleString(str) {
        const arr = str.split('');
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr.join('');
    }
}