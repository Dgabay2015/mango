pragma solidity ^0.4.14;
import './verifier.sol';
import './add_Instructor.sol';
import './class.sol';

// contract Data_Courses is Courses {
//     function setInstructor(address _address, uint _age, bytes16 _fName, bytes16 _lName){


//     }

// }

contract SumsToFifteen is Verifier, Courses, Class {
    bool public success = false;

    function verifyFifteen(
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[2] input,
        address _address,
        uint _age,
        bytes16 _fName,
        bytes16 _lName) public {
        // Verifiy the proof
        success = verifyTx(a, a_p, b, b_p, c, c_p, h, k, input);
        if (success) {
            // Proof verified
            setInstructor(_address, _age, _fName, _lName);


        } else {
            // Sorry, bad proof!
        }
    }
}
