var cube = (function () {
    function randomScramble() {
        var scramble = new scrambow.Scrambow().setType('333').get();

        return String(scramble[0]['scramble_string']);
    }

    function randomScramble4() {
        var scramble = new scrambow.Scrambow().setType('444').get();

        return String(scramble[0]['scramble_string']);
    }

    return {
        scramble: randomScramble,
        scramble4: randomScramble4
    };
})();