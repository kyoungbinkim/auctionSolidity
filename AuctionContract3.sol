pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

// ERC20 address : 0xdBdB7C3104bbc78D12B0B829c9D0959035e85a7e
// ERC721 address: 0xE556d85B039026b1030b05713eFa0db63781beF1
// contract address : 0x828ebF4a138d9E9630CDc1e05CE3B19087199370

/*s
베포자 : 0xE7FC40E4c1911a82aa9A2f9a7f589F8b491dd73D
Auction : 0xD37C587cb76Ac67AC7081249298Bd88C67c30594
Bidder1 : 0x784AC008c43d6551aF593b86A5057bEeC3716F54
Bidder2 : 0x34733b6E3cD51BDea9991660e2A47a33a0A34Cf7
Bidder3 : 0x2b9Cb6d97e9becb172ffc76684aBAdCD10bAF2be
*/

// approve  돈이 없어도 가능

contract AuctionContract3 {
    ERC20Contract private _erc20;
    ERC721Contract private _erc721;
    
    struct orderAuction{
        uint tokenId;
        uint deadLine;
        uint bidCount;
        uint priceLowerBound;
        bool openPriceFlag;
        string desc;
    }

    struct orderBid{
        uint tokenId;
        uint price;
        address from;
    }

    constructor(address erc20, address erc721) { 
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    } 

    
    mapping (uint => uint) private _idToAuctionListInd;
    mapping (uint => uint) private _idToHighestPrice;
    // mapping (uint => orderAuction) private _idToAuction;
    mapping (uint => bool) private _isEnrolledAuction;
    mapping (uint => orderBid[]) private _idToBidArray;

    modifier onlyOwnerOf(uint _tokenId){
        require(_erc721.ownerOf(_tokenId) == msg.sender, "only owner");
        _;
    }

    modifier ERC20CheckApprove(address sender, uint price){
        require(_erc20.allowance(sender, address(this)) >= price, "ERC20 : Authentication error");
        _;
    }

    modifier ERC20CheckBalance(uint _price){
        require(_erc20.balanceOf(msg.sender) >= _price, "ERC20 : not enough balance");
        _;
    }
    
    modifier ERC721CheckApprove(uint _tokenId){
        require(_erc721.getApproved(_tokenId) == address(this), "ERC721 : Authentication error");
        _;
    }

    modifier isEnrolled(uint _tokenId){
        require(_isEnrolledAuction[_tokenId],"is not Enrolled ! ");
        _;
    }

    orderAuction[] AuctionList;
    function getAuctionList() public view returns(orderAuction[] memory) {   
        return AuctionList;
    }

    function getHighestPrice(uint _tokenId) public view isEnrolled(_tokenId) returns (uint){
        require(_getOrderAuction(_tokenId).openPriceFlag, "openPrice is banned");
        return _idToHighestPrice[_tokenId];
    }
    
    function getDeadLine(uint _tokenId) isEnrolled(_tokenId) public view returns(uint){
        return AuctionList[_idToAuctionListInd[_tokenId]].deadLine;
    }

    function getLeftMin(uint _tokenId) isEnrolled(_tokenId) public view returns(uint){
        return (AuctionList[_idToAuctionListInd[_tokenId]].deadLine - block.timestamp) / 60;
    }

    function isAuctionInProcess(uint _tokenId) public view returns(bool){
        return _isEnrolledAuction[_tokenId];
    }

    function getBidCount(uint _tokenId) isEnrolled(_tokenId) public view returns(uint){
        return AuctionList[_idToAuctionListInd[_tokenId]].bidCount;
    }
    
    function getOrderAuction(uint _tokenId) isEnrolled(_tokenId) public view returns(orderAuction memory){
        return _getOrderAuction(_tokenId);
    }

    function _getOrderAuction(uint _tokenId) internal view returns(orderAuction storage){
        return AuctionList[_idToAuctionListInd[_tokenId]];
    }
 


    function enrollAuction(uint _tokenId, uint _days, uint _priceLowerBound, bool _openPriceFlag, string memory _desc) 
     public payable onlyOwnerOf(_tokenId) ERC721CheckApprove(_tokenId)
    {
        require(_days > 0 && !_isEnrolledAuction[_tokenId], "enroll Auction : wrong parameter");

        _isEnrolledAuction[_tokenId] = true;
        AuctionList.push(orderAuction(_tokenId, block.timestamp + (_days * 86400), 0, _priceLowerBound, _openPriceFlag, _desc));
        _idToAuctionListInd[_tokenId] = AuctionList.length - 1; 
        // _idToAuction[_tokenId] = AuctionList[_idToAuctionListInd[_tokenId]] ;
    }



    function enrollBid(uint _tokenId, uint _price) public ERC20CheckApprove(msg.sender, _price) ERC20CheckBalance(_price) {
        require(
            _getOrderAuction(_tokenId).deadLine > block.timestamp &&
            _getOrderAuction(_tokenId).priceLowerBound <= _price , "Wrong parameter ! s"
        );

        _idToBidArray[_tokenId].push(orderBid(_tokenId, _price, msg.sender));
        _getOrderAuction(_tokenId).bidCount++;

        if (_getOrderAuction(_tokenId).openPriceFlag && _idToHighestPrice[_tokenId] < _price){
            _idToHighestPrice[_tokenId] = _price;
            if (_getOrderAuction(_tokenId).deadLine - block.timestamp < 3600){
                _getOrderAuction(_tokenId).deadLine += 1 hours;
            }
        }
    }



    function auctionTermination(uint _tokenId) public onlyOwnerOf(_tokenId) {
        require( _erc721.getApproved(_tokenId) == address(this) 
        // && _idToAuction[_tokenId].deadLine <= block.timestamp
        , "auction termination error");
        address _tokenOwnerAddress = _erc721.ownerOf(_tokenId);
        
        while(_getOrderAuction(_tokenId).bidCount > 0){

            uint ind = _findHighestPriceBidInd(_tokenId);
            address _bidderAddress = _idToBidArray[_tokenId][ind].from;
            uint _price = _idToBidArray[_tokenId][ind].price;

            if (_erc20.balanceOf(_bidderAddress) >= _price) {
                _erc20.transferFrom(_bidderAddress, _tokenOwnerAddress, _price); 
                _erc721.transferFrom(_tokenOwnerAddress, _bidderAddress, _tokenId); 
                break;
            }
            else{
                delete _idToBidArray[_tokenId][ind];
                _getOrderAuction(_tokenId).bidCount--;
            }
        }
        delete _idToBidArray[_tokenId];
        _getOrderAuction(_tokenId).deadLine = 0;
        _isEnrolledAuction[_tokenId] = false;
    }

    function _findHighestPriceBidInd(uint _tokenId) public view returns(uint){ // 원래는 internal
        uint ind = 0;
        for(uint i=0; i<AuctionList[_idToAuctionListInd[_tokenId]].bidCount; i++){
            if (_idToBidArray[_tokenId][i].price > _idToBidArray[_tokenId][ind].price){
                ind = i;
            }
        }
        return ind;
    }
}