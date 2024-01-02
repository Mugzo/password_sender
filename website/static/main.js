// Update the characters count for the password textarea
const passwordLength = document.getElementById('passwordFormInput');
const passwordCounter = document.getElementById('passwordCounter');

// Send password button
const sendPasswordBtn = document.getElementById('sendPassword');

passwordLength.addEventListener('input', function(count) {
    const target = count.target;

    // Get the maxlength attribute
    const maxlength = target.getAttribute('maxlength');

    // Count the current number of characters
    const currentLength = target.value.length;

    passwordCounter.innerHTML = `${currentLength} / ${maxlength}`;

    // Enable the button if the textarea is not empty
    if (currentLength > 0) {
        sendPasswordBtn.disabled = false
    } else {
        sendPasswordBtn.disabled = true
    }
});
