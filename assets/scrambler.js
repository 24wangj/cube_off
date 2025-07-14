var cube = (function () {
    function randomScramble(eventID) {
        var scramble = new scrambow.Scrambow().setType(eventID).get();

        return String(scramble[0]['scramble_string']).replaceAll('\n', ' ').replaceAll('  ', ' ');
    }

    return {
        scramble: randomScramble,
    };
})();