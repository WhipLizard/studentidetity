// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentProfile {

    struct Student {
        string name;
        string collegeName;
        string rollNumber;
        string email;
        string studentId;
        string profileLink;
        bool exists;
    }

    struct Document {
        string documentName;
        string documentHash; // IPFS or similar file hash for the document
        string encryptedPasscodeHash; // Store the hash of the passcode
    }

    mapping(address => Student) public students;
    mapping(address => Document[]) private studentDocuments;

    event StudentRegistered(address indexed studentAddress, string profileLink);
    event DocumentUploaded(address indexed studentAddress, string documentName);
    event DocumentAccessed(address indexed studentAddress, string documentName);

    modifier onlyRegistered() {
        require(students[msg.sender].exists, "Student not registered");
        _;
    }

    // Register a new student
    function registerStudent(
        string memory _name,
        string memory _collegeName,
        string memory _rollNumber,
        string memory _email,
        string memory _studentId
    ) public {
        require(!students[msg.sender].exists, "Student already registered");

        // Create a profile link using the Ethereum address
        string memory profileLink = string(abi.encodePacked("https://eduinstituteX.io/profile/", toString(msg.sender)));

        students[msg.sender] = Student({
            name: _name,
            collegeName: _collegeName,
            rollNumber: _rollNumber,
            email: _email,
            studentId: _studentId,
            profileLink: profileLink,
            exists: true
        });

        emit StudentRegistered(msg.sender, profileLink);
    }

    // Upload a document
    function uploadDocument(
        string memory _documentName,
        string memory _documentHash,
        string memory _encryptedPasscodeHash
    ) public onlyRegistered {
        studentDocuments[msg.sender].push(Document({
            documentName: _documentName,
            documentHash: _documentHash,
            encryptedPasscodeHash: _encryptedPasscodeHash
        }));

        emit DocumentUploaded(msg.sender, _documentName);
    }

    // Get student profile details (public)
    function getStudentProfile(address _studentAddress) public view returns (
        string memory name,
        string memory collegeName,
        string memory rollNumber,
        string memory email,
        string memory studentId,
        string memory profileLink
    ) {
        require(students[_studentAddress].exists, "Student not registered");

        Student memory student = students[_studentAddress];
        return (
            student.name,
            student.collegeName,
            student.rollNumber,
            student.email,
            student.studentId,
            student.profileLink
        );
    }

    // Access a document with the correct passcode (non-view function)
    function accessDocument(address _studentAddress, uint _documentIndex, string memory _passcode) public returns (string memory documentHash) {
        require(students[_studentAddress].exists, "Student not registered");
        require(_documentIndex < studentDocuments[_studentAddress].length, "Invalid document index");

        Document memory doc = studentDocuments[_studentAddress][_documentIndex];
        
        // Verify the passcode
        require(keccak256(abi.encodePacked(_passcode)) == keccak256(abi.encodePacked(doc.encryptedPasscodeHash)), "Invalid passcode");

        emit DocumentAccessed(_studentAddress, doc.documentName);

        return doc.documentHash;
    }

    // Helper function to convert address to string
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
