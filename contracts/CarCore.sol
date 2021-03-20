pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// CarCore contract's method will be call through CarInteraction contract
// CarInteraction contract is the owner of CarCore and it will entry point for any method.

contract CarCore is Ownable{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => EnumerableSet.AddressSet) private _carHolders;
    
    // carAddressID => to owner
    mapping(address => address) public carToOwnerMapping;
    
    struct CarRecord {
        uint256 carPrice;
        bool isForSale;
        address carAddressID;
    }
    
    struct CarSellReciept {
        uint256 recieptNonce;
        uint256 price;
        uint256 timeStamp;
        address oldOwner;
        address newOwner;
        address carId;
    }
    
    // carAddressID => carRecord
    mapping(address => CarRecord) public carRecordMapping;
    
    // to track whole history of car selling
    // CarID => nonce => reciept
    mapping(address => mapping(uint256 => CarSellReciept)) public reciepts;
    
    // carId => TotalNonce
    mapping(address => uint256) public totalNonce;
    
    // New car will be add by CarInteraction contract(Owner)
    function addNewCar(address _admin, address _carAddressId, uint256 _price, bool _isSale) public onlyOwner returns(address) {
        require(contains(_admin, _carAddressId) == false, "ALready car added");
        
        CarRecord memory carRecord = CarRecord({
            carPrice: _price,
            carAddressID: _carAddressId,
            isForSale: _isSale
        });
        carRecordMapping[_carAddressId] = carRecord;
        
        carToOwnerMapping[_carAddressId] = _admin;
        
        _carHolders[_admin].add(_carAddressId);
        
        return _carAddressId;
    }
    
    // Only owner of car can change the details
    function updateSellCar(address _owner, address _carAddressId, bool _isSale, uint256 _price) public onlyOwner {
        require(contains(_owner, _carAddressId), "Not owner");
        
        carRecordMapping[_carAddressId].isForSale = _isSale;
        carRecordMapping[_carAddressId].carPrice = _price;
    } 
    
    // Buy car will be call by buyer
    function buyCar(address _newOwner, address _carAddressId) public payable {
        require(carRecordMapping[_carAddressId].isForSale, "Not For sale");
        require(carRecordMapping[_carAddressId].carPrice <= msg.value, "Price is not right");
        
        address payable carOwner = payable(carToOwnerMapping[_carAddressId]);
        uint256 nonce = totalNonce[_carAddressId].add(1);
        
        CarSellReciept memory carSellReciept = CarSellReciept({
            oldOwner: carOwner,
            newOwner: _newOwner,
            recieptNonce: nonce,
            price: msg.value,
            timeStamp: block.timestamp,
            carId: _carAddressId
        });
        
        reciepts[_carAddressId][nonce] = carSellReciept;
        totalNonce[_carAddressId] = nonce;
        
        carRecordMapping[_carAddressId].isForSale = false;
        carToOwnerMapping[_carAddressId] = _newOwner;
        
        _carHolders[carOwner].remove(_carAddressId);
        _carHolders[_newOwner].add(_carAddressId);
        
        carOwner.transfer(msg.value);
    }
    
    function lengths(address addr) public view returns(uint256) {
        return _carHolders[addr].length();
    }
    
    function at(address addr, uint256 index) public view returns(address){
        return _carHolders[addr].at(index);
    }
    
    function contains(address addr, address _carAddressId) public view returns(bool){
        return _carHolders[addr].contains(_carAddressId);
    }
    
    function balance(address addr) public view returns(uint256) {
        return address(addr).balance;
    }
}