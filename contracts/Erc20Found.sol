pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/SafeMath.sol';
//import './SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20Basic.sol';
//import './ERC20Basic.sol';

contract Foundation {
  uint addrSize;
  function resolveToName(address _addr) constant returns (bytes32) {}
  function getAddrLength(bytes32 _name) constant returns (uint) {}
  function getAddrIndex(bytes32 _name, uint index) constant returns (address) {}
  function hasName(address _addr) constant returns (bool) {}
  function areSameId(address _addr1, address _addr2) constant returns (bool) {}
}




/// one solution to the looping update variables problem is to allow users to have negative balances, this might be ok because as long as people use the balancesOf function it will return the expected value.




/**
 * @title Standard ERC20 token with support for FoundationId
 * @author Jared Bowie
 * @dev Implemantation of the ERC20Basic token from OpenZeppelin.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract Erc20Found is ERC20Basic {
  using SafeMath for uint;

  address foundationAddress = 0x17ff6026929c63a5855565b03c14a752897d8984;

  mapping(address => uint) private balances;
  mapping(bytes32 => uint) private balancesF;

  mapping (address => mapping (address => uint)) allowed;
  mapping(bytes32 => bool) foundP; //foundationid to bool
  mapping(bytes32 => bool) mutex;

  modifier isMutexed(bytes32 foundId) {
    require(mutex[foundId]==false);
    mutex[foundId]=true;  // Set exclusion and continue with function code
    _;
    mutex[foundId]=false; // release contract from exclusion
  }

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    //     if(msg.data.length < ) {
    //   throw;
    // }
     _;
  }


  function Erc20Found(uint adminBalance) {
    balances[msg.sender]=adminBalance;
  }


  //use this to display existing balances that haven't been transfered over
  function getFoundAddresses(bytes32 foundId) constant returns (address[]) {
    Foundation f = Foundation(foundationAddress);
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

  function hasFName(address _addr) constant returns (bool) {
    Foundation f = Foundation(foundationAddress);
    bool hasF = f.hasName(_addr);
    return hasF;
  }

  function areSameId(address _addr1, address _addr2) constant returns (bool) {
    Foundation f = Foundation(foundationAddress);
    bool areSameP = f.areSameId(_addr1, _addr2);
    return areSameP;
  }
  //checks if foundp is on

  function foundPTrue(address _addr) constant returns (bool anyAddrTrue) {
    require(hasFName(_addr));
    if (foundP[getFoundId(_addr)]) {
      return true;
    }
    else {
      return false;
    }
  }

  function transferF(bytes32 _foundIdTo, uint _value) onlyPayloadSize(2 * 32) {
    bytes32 foundIdFrom=getFoundId(msg.sender);
    if (foundP[foundIdFrom]==true) {
      balancesF[foundIdFrom] = balancesF[foundIdFrom].sub(_value);
      balancesF[_foundIdTo] = balancesF[_foundIdTo].add(_value);
      //      TransferFtF(msg.sender, _to, _value);
      }
    else {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balancesF[_foundIdTo] = balancesF[_foundIdTo].add(_value);
      //      TransferAtF(msg.sender, _to, _value);
    }
  }

  // fix to enable transfering from anywhere
  function tranToMyF(address _fromAddr) {
    require(balances[_fromAddr]>0);
    require(areSameId(msg.sender, _fromAddr));
    uint totalBalance;
    bytes32 foundId=getFoundId(msg.sender);
    require(foundP[foundId]==true);
    totalBalance = balances[_fromAddr];
    balances[_fromAddr] = balances[_fromAddr].sub(totalBalance);
    balancesF[foundId] = balancesF[foundId].add(totalBalance);
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    bytes32 foundId=getFoundId(msg.sender);
    if (foundP[foundId]==true) {
      balancesF[foundId] = balancesF[foundId].sub(_value);
      balances[_to] = balances[_to].add(_value);
      //Transfer(msg.sender, _to, _value);
      }
    else {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
    }

  }




  // the security concern here is what happens when a user deletes addresses from his foundationid
  // we also can't loop through addresses to transfer balances

  function turnOnFoundP() returns (bool success) {
    require(hasFName(msg.sender)==true);
    bytes32 foundId = getFoundId(msg.sender);
    uint totalBalance;
    // turn off
    if (foundP[foundId]==true) {
      foundP[foundId]=false;
      totalBalance =  balancesF[foundId];
      balancesF[foundId]= balancesF[foundId].sub(totalBalance);
      balances[msg.sender]=balances[msg.sender].add(totalBalance);
    }
    // turn on
    else {
      foundP[foundId]=true;
      totalBalance =  balances[msg.sender];
      balances[msg.sender]=balances[msg.sender].sub(totalBalance);
      balancesF[foundId]=balancesF[foundId].add(totalBalance);
    }
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


  // must prevent any usage of addresses while in operation
  //

  /// this doesn't work as a loop because of unknown gas costs to loop


  /*
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */



  ///don't need this anymore?
  function balanceOfAll(bytes32 foundId) private constant returns (uint balance) {
    uint totalBalance;
    address[] memory allAddr=getFoundAddresses(foundId);
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
    bytes32 foundId=getFoundId(_owner);
    if (foundP[foundId]==true) {
      return balancesF[foundId];
    }
    else {
      return balances[_owner];
    }
  }
}
