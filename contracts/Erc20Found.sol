pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/SafeMath.sol';
//import './SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20Basic.sol';
//import './ERC20Basic.sol';

contract Foundation {
  uint addrSize;
  function resolveToName(address _addr) constant returns (bytes32) {  }
  function getAddrLength(bytes32 _name) constant returns (uint) {  }
  function getAddrIndex(bytes32 _name, uint index) constant returns (address) {  }
}


/**
 * @title Standard ERC20 token with support for FoundationId
 * @author Jared Bowie
 * @dev Implemantation of the ERC20Basic token from OpenZeppelin.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract Erc20Found is ERC20Basic {
  using SafeMath for uint;

  address foundationAddress = 0xd615d0FCfE6c460AA79cdCfA82B3b420A7E89503;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  mapping(bytes32 => bool) foundP; //foundationid to bool


  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }


  function Erc20Found(uint adminBalance) {
    balances[msg.sender]=adminBalance;
  }

  function getFoundAddresses(address _addr) constant returns (address[]) {
    Foundation f = Foundation(foundationAddress);
    bytes32 foundId = f.resolveToName(_addr);
    uint addrLength = f.getAddrLength(foundId);
    address[] storage allAddr;
    for (uint i=0; i < addrLength; i++) {
      allAddr.push(f.getAddrIndex(foundId, i));
    }
    return allAddr;
  }

  function getFoundId(address _addr) constant returns (bytes32) {
    Foundation f = Foundation(foundationAddress);
    bytes32 foundId = f.resolveToName(_addr);
    return foundId;

  }

  //checks if foundp is on

  function foundPTrue(address _addr) constant returns (bool anyAddrTrue) {
    if (foundP[getFoundId(_addr)]) {
      return true;
    }
    else {
      return false;
    }
  }

  function toggleFoundP() returns (bool success) {
    Foundation f = Foundation(foundationAddress);
    bytes32 foundId = f.resolveToName(msg.sender);
    foundP[foundId]=!foundP[foundId];
    return true;
  }

  /*
   * @dev Transfer tokens from one address to another
   * @dev If foundation support is enabled for user
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  /*
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    uint _allowance;
    if (areSameId(_from, _to)) {
      _allowance = balaces[_from];
    }
    else {
      _allowance = allowed[_from][msg.sender];
    }

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }*/

  /*
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  /*
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  */
  /*
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  /*
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  */
  /*
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */


  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /* function areSameId(address _addr1, address _addr2) constant returns (bool) {
    Foundation f = Foundation(foundationAddress);
    return f.areSameId(_addr1, _addr2);
  }
  */


  function balanceOfF(address _owner) private constant returns (uint balance) {
    uint totalBalance;
    address[] memory allAddr=getFoundAddresses(_owner);
    for (uint p = 0; p < allAddr.length; p++) {
      address oneAddress=allAddr[p];
      totalBalance=totalBalance + balances[oneAddress];
    }
    return totalBalance;
  }

  /*
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    if (foundP[getFoundId(_owner)]) {
      return balanceOfF(_owner);
    }
    else {
      return balances[_owner];
    }
  }


}
