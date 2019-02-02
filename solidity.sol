pragma solidity ^0.4.18;

// contract Coursetro {

//     string fName;
//     uint age;

//     function setInstructor(string _fname, uint _age)public{
//         fName = _fname;
//         age = _age;

//     }
//     function getInstructor() public constant returns (string, uint){

//         return(fName, age);
//     }

// }


library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x2fb77be9d36da3f214a5bda79d21f00812b4360390eceb31ecc61229089717e6, 0x48c648f4c141f18e5913a03b10dd7a69b581b8bd2eef3fa5189d3b88f12cf5d], [0x2dfe90da5047704b478c0155b4120e945f63eb433035efa600fba4345eda676e, 0x1ad5a6021110b2a3705d092287d875523e5f0050223707c1bd0d35ee029bca23]);
        vk.B = Pairing.G1Point(0x2ef9765a78b7a16575b88fdb90ed0ddc99fa2955cf4b0ed9d46f4fa8debaae88, 0x19bdb378cda859c70e48f47cf2c944d137b1180c0442c157b2440e5e85bda36e);
        vk.C = Pairing.G2Point([0x12bb49501775858dc5d2e8caf117a13fb9acf72fcc641ea97731ed647ef8d8d9, 0x137b1034cc3192332650b03b7f733b878acbf9f55824e326e4ac1c7b4aef9628], [0x21ed87ab78ccc42406316153ab6f2d460cc2e83b7daf6e067dad450f437fd3b2, 0x2c20e88f04e3b2e590643686389ecbef798f442c2367d980beb1616dd15fab8b]);
        vk.gamma = Pairing.G2Point([0x2a5065ea28cdbaa831dea910879a5f8adaa8e0f59ca62b7cbf1b7479ea953681, 0xb6242b0afb4cc6ad5f2ab0145e79804ba69fb4f04190c98d438a16ec12d6c9], [0x20b75137550b45fdd89f629143cfffc55df564c0c4378d8115a07b2ebbb06835, 0x2dbce337bf0a24832ce86a63c0dc6f88b5efe2ac9f580f6e8f6c3e3daec4858a]);
        vk.gammaBeta1 = Pairing.G1Point(0x24a4715c1df694aa37be5af4e70cace186afad89aebdf8033a79559c14dff29a, 0x201055eb6f225968d172b1ca012e4de7bd4fd064000d74f1435790bfc2e5778f);
        vk.gammaBeta2 = Pairing.G2Point([0x1f89ed6d9c03908e488ad4ef8d8dafd3b5369a830fc9890f8ddb4a986e3ade53, 0x2ae094610ab71f4b1349133f35cc6dca607ab38a75e489a944472e05cc9b1ce7], [0x89c8f92c5475469f207afc061a0b85464427a4734986ef0a551a1c453e1f284, 0x16ceaf2bb6d2655c8398c40969ce916483f75b376a4e5e98422f26d7074ec52d]);
        vk.Z = Pairing.G2Point([0x276d08da8f1b60ff13aed762235eae79b7495da163dbf9e8a5524f3e4d4a852a, 0x2a011f3199905c11d9f8425d98f3667326d4fed67f27b7fbd55481f3535190da], [0x13b92fd64d0785da3e9f80cdb612a1a08bd015efb74cc9d83cb1468b95bacc00, 0xe14e8e83587420541f41960b13aa668cf898c9025e6b0eb32a72ea513999a61]);
        vk.IC = new Pairing.G1Point[](3);
        vk.IC[0] = Pairing.G1Point(0xd33b730a5aa83f9dacd00f9496c6b2ccc9bf51356fc4fd0d13f8ef4f2272597, 0x16b2bf7f56528cb3901616b15504ed75879b9387b8efda428d9197e16b73bb9c);
        vk.IC[1] = Pairing.G1Point(0x34e9d3c81f6b231ddb4791807df5249e6dc712318953096e6bbb1a9e715554d, 0x115a1576eda0c75872e4738bb9055a077a2db68168bc5df61d3df5cbee0eb1a5);
        vk.IC[2] = Pairing.G1Point(0x2c9b8857c73e7f60cfea5dde404eb1edd718f39fea144992b2d4b380dbc3fb49, 0x295e78b418317c4b7225c49ea1f2fbd6a03b0812f2a65fbc05598a988973c3fd);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[2] input
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
