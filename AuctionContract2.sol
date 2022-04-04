pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

// ERC20 address : 0x5909CD5CD2F5f1e3F54E9c8623A60258d4D722A7
// ERC721 address: 0x1F7F5D75686c1004f2F1bD318bbd846e75dD23d7

contract AuctionContract2 {

    struct Auction{
        uint auctionNum;
        uint tokenId;
        uint deadLine;
        uint bidLen;
        string desc;
    }
    
    struct Bid{
        uint auctionNum;
        uint bidNum;
        uint nextBidNum;
        uint price;
        address from;
    }

    ERC20Contract private _erc20;
    ERC721Contract private _erc721;
    uint auctionIndex = 0;
    uint bidIndex = 0;
    Auction[] AuctionList;

    constructor(address erc20, address erc721) { // 토큰 instance 설정
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    } 

    

    // mapping (uint256 => Auction) private _tokenIdToAuction;
    mapping (uint => Auction) private _numToAuction; // auctionNum -> Auction
    mapping (uint => Bid) private _numToBid;
    mapping (uint => Bid) private _auctionNumToBid;

    function getAuctionList() public view returns(Auction[] memory) {
        return AuctionList;
    }

    function enrollAuction(uint _tokenId, uint _deadLine, string memory _desc) public payable {
        require( // 실제 토큰소유자가 호출했는지, 권한 위임(별개)했는지 체크
            _erc721.ownerOf(_tokenId) == msg.sender &&
            _erc721.getApproved(_tokenId) == address(this),
            "enroll Auction : Authentication error"
        );
        require(_deadLine > block.timestamp, "wrong dead line !");

        
        _numToAuction[auctionIndex] =  Auction(auctionIndex, _tokenId, _deadLine, 0, _desc);
        AuctionList.push(_numToAuction[auctionIndex]);

        auctionIndex++;
    }

    function bidding(uint auctionNum, uint price) public {
        require(_numToAuction[auctionNum].deadLine > block.timestamp, "Wrong auctionNum ! ");
        _numToBid[bidIndex] = Bid(auctionNum, bidIndex, bidIndex, price, msg.sender);
        _numToAuction[auctionNum].deadLine = _numToAuction[auctionNum].deadLine + 1 hours;
        
        if(_numToAuction[auctionNum].bidLen == 0){
            _auctionNumToBid[auctionNum] = _numToBid[bidIndex];
            _numToAuction[auctionNum].bidLen++;
        }
        else if(_numToAuction[auctionNum].bidLen == 1){
            if(_auctionNumToBid[auctionNum].price > _numToBid[bidIndex].price){
                _auctionNumToBid[auction].nextBidNum = bidIndex;
            }
            else{
                uint tmp = _auctionNumToBid[auction].bidNum;
                _auctionNumToBid[auctionNum] = _numToBid[bidIndex];
                _numToBid[bidIndex].nextBidNum = tmp;
            }
        }
        else{
            Bid tmp = _auctionNumToBid[auctionNum];
            while (tmp.bidNum != tmp.nextBidNum){
                
            }
        }
        

        bidIndex++;
    }
    
    function _checkDeadLine() internal view returns (uint, uint) {
        for (uint i=0; i<AuctionList.length ; i++){
            if (AuctionList[i].deadLine <= block.timestamp){
                return (AuctionList[i].auctionNum, i);
            }
        }
        return (auctionIndex, AuctionList.length);
    }

    function _checkDeadLineAuctionNum(uint auctionNum) internal view returns (bool , uint){
        bool result;
        uint index = AuctionList.length;
        if (_numToAuction[auctionNum].deadLine <= block.timestamp){
            result = true;
        }
        else{
            result = false;
            return (result, index);
        }
        for (uint i=0; i<AuctionList.length; i++){
            if (AuctionList[i].auctionNum == auctionNum){
                index = i;
                break;
            }
        }
        return (result, index);
    }

    function _findHighestBid(uint auctionNum) internal returns(){
        require(_numToAuction[auctionNum].deadLine <= block.timestamp);
        uint len = _auctionNumToBid[auctionNum].length;
        
    }

    function dealingAuction(uint auctionNum) public {
        bool checkDeadLine;
        uint auctionListind;
        (checkDeadLine,auctionListind) = _checkDeadLineAuctionNum(auctionNum);
        require(checkDeadLine, "dead line is left");


    }
}