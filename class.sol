pragma solidity ^0.4.18;


import './add_Instructor.sol';


// contract Owned {
//     address owner;

//     function Owned() public {
//         owner = msg.sender;
//     }

//   modifier onlyOwner {
//       require(msg.sender == owner);
//       _;
//   }
// }

contract Class is Owned{

    struct Class {
        uint age;
        bytes16 fName;
        bytes16 lName;
        address [] classentries;
    }

    mapping (address => Class) classes;
    address[] public classesAccts;

    event classInfo(
       bytes16 fName,
       bytes16 lName,
       uint age
    //   address [] classentries
    );

    function setClass(address _address, uint _age, bytes16 _fName, bytes16 _lName) onlyOwner public {
        var class = classes[_address];

        class.age = _age;
        class.fName = _fName;
        class.lName = _lName;


        classesAccts.push(_address) -1;
        classInfo(_fName, _lName, _age);
    }
    function add_Entry(address _address, address user_address) public {
        var class = classes[_address];
        // add user address to this classes array of entries
        class.classentries.push(user_address);
        // class.fName = _fName;
        // class.lName = _lName;

        // classesAccts.push(_address) -1;
        // classInfo(_fName, _lName, _age);
    }

    function getClasses() view public returns(address[]) {
        return classesAccts;
    }

    function getClass(address _address) view public returns (uint, bytes16, bytes16, address[]) {
        return (classes[_address].age, classes[_address].fName, classes[_address].lName, classes[_address].classentries);
    }

    function countClasses() view public returns (uint) {
        return classesAccts.length;
    }

}
