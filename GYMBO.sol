// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./GYM.sol";

contract GymMembership is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;
    using Strings for uint256; 

    string public baseURI = "https://isaac-eth.github.io/GymMemFinalPro/";

    GymToken public gym;

    struct memType {
        string memTypeName;
        uint256 memVigency;
        uint256 memCost;
        uint256 memBonus;
    }

    memType[] allMemberships;
    
    string[] AllExtraClassess;

    uint256 minVisitTime = 15;
    uint256 weekTime = 300;
    uint256 dayTime = 60;

    struct visits {
        bool status;
        uint256 enterTime;
        uint256 exitTime;
        uint256 lastExitTime;
        uint256 vigency;
        uint256 visitDuration;
        uint256 completedVisits;
        uint256 endOfWeek;
    }

    mapping (address => visits) VisitsInfo;

    constructor(address _gymAddress) ERC721("Gymbo Membership", "GBMS") Ownable(msg.sender) {
        gym = GymToken(_gymAddress);
        memType memory MonthMembership = memType ({
            memTypeName: "One Month",
            memVigency: 600,
            memCost: 100,
            memBonus: 5000000000000000000
        });
        allMemberships.push(MonthMembership);

        memType memory triMonthMembership = memType ({
            memTypeName: "Three Months",
            memVigency: 180,
            memCost: 3,
            memBonus: 20000000000000000000
        });
        allMemberships.push(triMonthMembership);

        memType memory sixMonthMembership = memType ({
            memTypeName: "Six Months",
            memVigency: 360,
            memCost: 6,
            memBonus: 30000000000000000000
        });
        allMemberships.push(sixMonthMembership);

        memType memory anualMembership = memType ({
            memTypeName: "Anual",
            memVigency: 720,
            memCost: 12,
            memBonus: 60000000000000000000
        });
        allMemberships.push(anualMembership);

        string memory cross = "Cross";
        AllExtraClassess.push(cross);
        string memory cardio = "Cardio";
        AllExtraClassess.push(cardio);
        string memory gap = "Gap";
        AllExtraClassess.push(gap);
        string memory yoga = "Yoga";
        AllExtraClassess.push(yoga);
    }

    event MembershipAcquired (address indexed buyer, uint256 membershipType, uint256 bonusTokens, uint256 expirationDate);
    event EnterRegistered (address indexed member, uint256 enterTime);
    event ExitRegistered (address indexed member, uint256 exitTime, uint256 completedVisitsInWeek, uint256 endOfWeek);
    event BonusTokensReward (address indexed member, uint256 tokenReward);
    event ExtraClassSigned (address indexed member, uint256 extraClassNumber);
    event ExtraClassAdded (address indexed owner, string newClass);
    event ExtraClassDeleted (address indexed owner, string deletedClass);
    event PriceUpdate (address indexed owner, uint256 updatedMem, uint256 newPrice);
    event DeleteMembership (address indexed owner, uint256 deletedMem);

    function addExtraClass (string memory _newCLass) public onlyOwner {
        AllExtraClassess.push(_newCLass);
        emit ExtraClassAdded (msg.sender, _newCLass);
    }

    function deleteExtraClass (uint256 _classToDelete) public onlyOwner {
        require (_classToDelete < AllExtraClassess.length, "This class does not exist");
        uint256 index = _classToDelete;
        AllExtraClassess[index] = AllExtraClassess[AllExtraClassess.length - 1];
        AllExtraClassess.pop();
        emit ExtraClassDeleted (msg.sender, AllExtraClassess[_classToDelete]);
    }

    function changeMembership (uint256 _membership, uint256 _newPrice) public onlyOwner {
        require (_membership < allMemberships.length, "This membership does not exist");
        memType storage memToUpdate = allMemberships[_membership];
        memToUpdate.memCost = _newPrice;
        emit PriceUpdate (msg.sender, _membership, _newPrice);
    }

    function deleteMembership (uint256 _membership) public onlyOwner {
        require (_membership < allMemberships.length, "This membership does not exist");
        uint256 index = _membership;
        allMemberships[index] = allMemberships[allMemberships.length - 1];
        allMemberships.pop();
        emit DeleteMembership (msg.sender, _membership);
    }

    function seeAllMemberships() public view returns (memType[] memory) {
        return allMemberships;
    }

    function seeAllExtraClassess () public view returns (string[] memory) {
        return AllExtraClassess;
    }
    
    function buyMembership(address to, uint256 _memType) public payable {
        require (VisitsInfo[msg.sender].vigency <= block.timestamp, "You already have a Membership");
        require (_memType < allMemberships.length, "Select only available Membership");
        memType storage SelectedMembership = allMemberships[_memType];
        require (msg.value == SelectedMembership.memCost, "Payment not valid");

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(to, tokenId);

        VisitsInfo[msg.sender].vigency = block.timestamp + SelectedMembership.memVigency;
        VisitsInfo[msg.sender].completedVisits = 0;

        gym.transfer(msg.sender, SelectedMembership.memBonus);
        
        emit MembershipAcquired (to, _memType, SelectedMembership.memBonus, VisitsInfo[msg.sender].vigency);
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "NFT does not exist");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function enterGym () public {
       require (!VisitsInfo[msg.sender].status, "Member already entered gym");
       require (block.timestamp <= VisitsInfo[msg.sender].vigency, "Membership has expired");
       VisitsInfo[msg.sender].status = !VisitsInfo[msg.sender].status;
       VisitsInfo[msg.sender].enterTime = block.timestamp;
       
       if(block.timestamp > VisitsInfo[msg.sender].endOfWeek) {
            VisitsInfo[msg.sender].completedVisits = 0;
        }

        emit EnterRegistered (msg.sender, block.timestamp);
    }

    function exitGym () public {
        require (VisitsInfo[msg.sender].status, "Member already exited gym");
        VisitsInfo[msg.sender].status = !VisitsInfo[msg.sender].status;
           
        VisitsInfo[msg.sender].visitDuration = block.timestamp - VisitsInfo[msg.sender].enterTime;

        if(VisitsInfo[msg.sender].completedVisits == 0) {
            VisitsInfo[msg.sender].exitTime = block.timestamp;   
            VisitsInfo[msg.sender].endOfWeek = block.timestamp + weekTime;  
            if(VisitsInfo[msg.sender].visitDuration >= minVisitTime) {
                VisitsInfo[msg.sender].completedVisits++;
                VisitsInfo[msg.sender].lastExitTime = block.timestamp;
            }
        } else if(VisitsInfo[msg.sender].visitDuration >= minVisitTime) {
                if(block.timestamp > VisitsInfo[msg.sender].lastExitTime + dayTime) {
                    VisitsInfo[msg.sender].completedVisits++;
                    VisitsInfo[msg.sender].lastExitTime = block.timestamp;
                } else {
                    VisitsInfo[msg.sender].exitTime = block.timestamp;
                }
            }

        emit ExitRegistered (msg.sender, block.timestamp, VisitsInfo[msg.sender].completedVisits, VisitsInfo[msg.sender].endOfWeek);
    }

    function claimRewards () public {
         require(block.timestamp > VisitsInfo[msg.sender].endOfWeek, "Week period is not over");
         if (VisitsInfo[msg.sender].completedVisits == 4) {
            gym.transfer(msg.sender, 4000000000000000000);
            emit BonusTokensReward (msg.sender, 4);
        } else if (VisitsInfo[msg.sender].completedVisits > 4) {
            gym.transfer (msg.sender, 15000000000000000000);
            emit BonusTokensReward (msg.sender, 15);
        }
    }

    function consultMembership () public view returns (visits memory) {
        return VisitsInfo[msg.sender];
    }

    function signInExtraClass (uint256 _extraClass) public {
        require(gym.balanceOf(msg.sender) >= (5),"Not enough GYM balance");
        require (_extraClass < AllExtraClassess.length, "Extra class not valid");
        gym.transferFrom(msg.sender, address(this), 5);
        emit ExtraClassSigned (msg.sender, _extraClass);
    }
}