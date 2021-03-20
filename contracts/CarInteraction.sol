pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CarCore.sol";

interface ICarStorage {
    function addNewCar(address _admin, address _carAddress, uint256 _price, bool _isSale) external;
    function updateSellCar(address _owner, address _carAddress, bool _isSale, uint256 _price) external;
    function buyCar(address _newOwner, address _carAddress) external payable;
}

// CarInteraction contract is the owner of CarCore and it will entry point for any method.
contract CarInteraction is Ownable {
    ICarStorage public iCarStorage;
    
    constructor(address _iCarStorage) public {
        iCarStorage = ICarStorage(_iCarStorage);
    }
    
    function addNewCarByOwner(uint256 _price, bool _isSale) public onlyOwner {
        bytes memory bytecode = type(CarCore).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(address(iCarStorage), block.timestamp));
        address _carAddressId = Create2.deploy(0, salt, bytecode);
        iCarStorage.addNewCar(msg.sender, _carAddressId, _price, _isSale);
    }
    
    function updateCarSellAndPrice(address _carAddressId, bool _isSale, uint256 _price) public {
        iCarStorage.updateSellCar(msg.sender, _carAddressId, _isSale, _price);
    }
    
    function buyCarByAnyUser(address _carAddressId) public payable {
        iCarStorage.buyCar{value: msg.value}(msg.sender, _carAddressId);
    }
}