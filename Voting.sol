pragma solidity ^0.4.11;

contract Pooling {
	address owner;
	address mixer;
	mapping (address => bool) public registered;
	mapping (address => uint) public votesLeft;
	mapping (address => uint) public addressRating;
	uint lowerAddressRating;
	uint mediumAddressRating;
	uint upperAddressRating;

	bytes32[] questions;
	mapping (address => mapping (uint => bytes32)) answers;

	struct AnswerRating{
		uint against;
		uint placets; // = votes for = positive votes.
	}
	mapping (address => mapping (uint => AnswerRating)) answersRating;

	mapping (uint => mapping (address => bool)) votedForAnswer;

	mapping (address => bytes32) public votersSecrets;
	mapping (bytes32 => uint) public votersSecretsToRatingPower;
	uint summaryNewRating;
	mapping (address => uint) newRatingPowers;

	function Pooling(uint lowerAddressRatingToAllowEvaluatingAnswers, uint mediumAddressRatingToAllowEvaluatingAnswers, uint upperAddressRatingToAllowEvaluatingAnswers, address mixerAddress) {
		lowerAddressRating = lowerAddressRatingToAllowEvaluatingAnswers;			
		mediumAddressRating = mediumAddressRatingToAllowEvaluatingAnswers;
		upperAddressRating = upperAddressRatingToAllowEvaluatingAnswers;
		owner = msg.sender;
		mixer = mixerAddress;
	}

	function registerMe() {
		require(!registered[msg.sender]);
		registered[msg.sender] = true;
		registeredList.push(msg.sender);
		votesLeft[msg.sender] = 3;
	}

    modifier onlyRegistered {
        require(registered[msg.sender]);
        _;
    }

	function voteForAddress(address votedFor, uint votes) onlyRegistered {
		require(votesLeft[msg.sender] - votes >= 3);
		votesLeft[msg.sender] -= votes;
		addressRating[votedFor] += votes;
	}

	modifier canAnswer {
		require(addressRating[msg.sender] >= upperAddressRating);
		_;
	}

	function answerQuestion(bytes32 answer, uint questionId) canAnswer {
		require(answers[msg.sender][questionId].length == 0); // will it work?? try == undefined
		answers[msg.sender][questionId] = answer;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function addQuestion(bytes32 questionText) onlyOwner {
		questions.push(questionText);
	}

	function promulgateMySecret(bytes32 secret) {
		require(votersSecrets[msg.sender].length == 0);
		votersSecrets[msg.sender] = secret;
		uint ratingPower = computeRatingPowerFromRating(addressRating[msg.sender]);
		votersSecretsToRatingPower[secret] = ratingPower;
		summaryNewRating += ratingPower;
	}

	modifier onlyMixer{
		require(msg.sender == mixer);
		_;
	}

	function setRatingPower(address voterForAnswers, uint ratingPower) onlyMixer {
		require(summaryNewRating - ratingPower >= 0);
		newRatingPowers[voterForAnswers] = ratingPower;
		summaryNewRating -= ratingPower;
	}

	modifier canVoteForAnswer {
		require(addressRating[msg.sender] >= lowerAddressRating);
		_;
	}

	function voteForAnswer(address answerer, uint questionId, bool isVoteAgainst) canVoteForAnswer {
		require(!votedForAnswer[questionId][msg.sender]);
		uint newRatingPower = votersSecretsToRatingPower[votersSecrets[msg.sender]];
		if (isVoteAgainst) {
			answersRating[answerer][questionId].against += newRatingPower; // do I have to initialize first??
		} else {
			answersRating[answerer][questionId].placets += newRatingPower;
		}
		votedForAnswer[questionId][msg.sender] = true;
	}	

	function computeRatingPowerFromRating(uint rating) returns (uint ratingPower) {
		ratingPower = 5;
		if (rating >= mediumAddressRating)
			ratingPower = 10;
		if (rating >= upperAddressRating)
			ratingPower = 20;
		return ratingPower;
	}
}
//0x9443dACc146440ab42C507F493b384ee56b8Aa16
//0x88Fb1370BA8d9f7cE7b3cCED093a9E123b943004