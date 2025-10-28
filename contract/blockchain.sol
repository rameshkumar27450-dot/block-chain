// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SkillVerificationPassport
 * @dev A decentralized system for verifying skills and maintaining lifelong learning records
 */
contract SkillVerificationPassport {
    
    struct Skill {
        string skillName;
        string category;
        address verifier;
        uint256 timestamp;
        string evidenceURI;
        bool isVerified;
    }
    
    struct LearnerProfile {
        address learnerAddress;
        string name;
        uint256 skillCount;
        bool isActive;
    }
    
    // Mappings
    mapping(address => LearnerProfile) public learnerProfiles;
    mapping(address => mapping(uint256 => Skill)) public learnerSkills;
    mapping(address => bool) public authorizedVerifiers;
    
    address public admin;
    uint256 public totalLearners;
    
    // Events
    event LearnerRegistered(address indexed learner, string name);
    event SkillAdded(address indexed learner, uint256 skillId, string skillName);
    event SkillVerified(address indexed learner, uint256 skillId, address verifier);
    event VerifierAuthorized(address indexed verifier);
    event VerifierRevoked(address indexed verifier);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Not an authorized verifier");
        _;
    }
    
    modifier onlyActiveLearner() {
        require(learnerProfiles[msg.sender].isActive, "Learner profile not active");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        authorizedVerifiers[msg.sender] = true;
    }
    
    /**
     * @dev Register a new learner profile
     * @param _name Name of the learner
     */
    function registerLearner(string memory _name) public {
        require(!learnerProfiles[msg.sender].isActive, "Learner already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        learnerProfiles[msg.sender] = LearnerProfile({
            learnerAddress: msg.sender,
            name: _name,
            skillCount: 0,
            isActive: true
        });
        
        totalLearners++;
        emit LearnerRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Add a new skill to learner's passport
     * @param _skillName Name of the skill
     * @param _category Category of the skill (e.g., "Programming", "Design")
     * @param _evidenceURI URI pointing to evidence/certificate
     */
    function addSkill(
        string memory _skillName,
        string memory _category,
        string memory _evidenceURI
    ) public onlyActiveLearner {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty");
        
        uint256 skillId = learnerProfiles[msg.sender].skillCount;
        
        learnerSkills[msg.sender][skillId] = Skill({
            skillName: _skillName,
            category: _category,
            verifier: address(0),
            timestamp: block.timestamp,
            evidenceURI: _evidenceURI,
            isVerified: false
        });
        
        learnerProfiles[msg.sender].skillCount++;
        emit SkillAdded(msg.sender, skillId, _skillName);
    }
    
    /**
     * @dev Verify a learner's skill (only authorized verifiers)
     * @param _learner Address of the learner
     * @param _skillId ID of the skill to verify
     */
    function verifySkill(address _learner, uint256 _skillId) 
        public 
        onlyAuthorizedVerifier 
    {
        require(learnerProfiles[_learner].isActive, "Learner not found");
        require(_skillId < learnerProfiles[_learner].skillCount, "Invalid skill ID");
        require(!learnerSkills[_learner][_skillId].isVerified, "Skill already verified");
        
        learnerSkills[_learner][_skillId].isVerified = true;
        learnerSkills[_learner][_skillId].verifier = msg.sender;
        
        emit SkillVerified(_learner, _skillId, msg.sender);
    }
    
    /**
     * @dev Authorize a new verifier (only admin)
     * @param _verifier Address of the verifier to authorize
     */
    function authorizeVerifier(address _verifier) public onlyAdmin {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Verifier already authorized");
        
        authorizedVerifiers[_verifier] = true;
        emit VerifierAuthorized(_verifier);
    }
    
    /**
     * @dev Revoke verifier authorization (only admin)
     * @param _verifier Address of the verifier to revoke
     */
    function revokeVerifier(address _verifier) public onlyAdmin {
        require(authorizedVerifiers[_verifier], "Verifier not authorized");
        require(_verifier != admin, "Cannot revoke admin");
        
        authorizedVerifiers[_verifier] = false;
        emit VerifierRevoked(_verifier);
    }
    
    /**
     * @dev Get learner profile information
     * @param _learner Address of the learner
     */
    function getLearnerProfile(address _learner) 
        public 
        view 
        returns (
            string memory name,
            uint256 skillCount,
            bool isActive
        ) 
    {
        LearnerProfile memory profile = learnerProfiles[_learner];
        return (profile.name, profile.skillCount, profile.isActive);
    }
    
    /**
     * @dev Get specific skill details
     * @param _learner Address of the learner
     * @param _skillId ID of the skill
     */
    function getSkill(address _learner, uint256 _skillId)
        public
        view
        returns (
            string memory skillName,
            string memory category,
            address verifier,
            uint256 timestamp,
            string memory evidenceURI,
            bool isVerified
        )
    {
        require(_skillId < learnerProfiles[_learner].skillCount, "Invalid skill ID");
        Skill memory skill = learnerSkills[_learner][_skillId];
        return (
            skill.skillName,
            skill.category,
            skill.verifier,
            skill.timestamp,
            skill.evidenceURI,
            skill.isVerified
        );
    }
    
    /**
     * @dev Get count of verified skills for a learner
     * @param _learner Address of the learner
     */
    function getVerifiedSkillCount(address _learner) public view returns (uint256) {
        uint256 count = 0;
        uint256 totalSkills = learnerProfiles[_learner].skillCount;
        
        for (uint256 i = 0; i < totalSkills; i++) {
            if (learnerSkills[_learner][i].isVerified) {
                count++;
            }
        }
        return count;
    }
}
