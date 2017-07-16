pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/SafeMath.sol';
//import './SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20Basic.sol';
//import './ERC20Basic.sol';

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


  mapping (address => mapping (address => uint)) allowedAtoA;
  mapping (address => mapping (bytes32 => uint)) allowedAtoF;
  mapping (bytes32 => mapping (address => uint)) allowedFtoA;
  mapping (bytes32 => mapping (bytes32 => uint)) allowedFtoF;


  mapping(bytes32 => bool) foundP; //foundationid to bool
  mapping(bytes32 => bool) mutex;

  event Approval(address indexed owner, address indexed spender, uint value);

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


  //////////////////////////////////////////////
  //////////FOUNDATION FUNCTIONS ///////////////
  //////////////////////////////////////////////

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

  function useFoundP(address _addr) private constant returns (bool) {
    if (hasFName(_addr) && foundP[getFoundId(_addr)]==true) {
      return true;
    }
    else {
      return false;
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


  function transferAtoA (address _from, address _to, uint _value) private {
    require(balances[_from]>=_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
  }

  function transferAtoF  (address _from, address _to, uint _value) private {
    require(hasFName(_to) && foundP[getFoundId(_to)]==true);
    require(balances[_from]>=_value);
    bytes32 toF = getFoundId(_to);
    balances[_from] = balances[_from].sub(_value);
    balancesF[toF] = balancesF[toF].add(_value);
  }

  function transferFtoF  (address _from, address _to, uint _value) private {
    require(hasFName(_from) && foundP[getFoundId(_from)]==true);
    require(hasFName(_to) && foundP[getFoundId(_to)]==true);
    bytes32 fromF = getFoundId(_from);
    require(balancesF[fromF]>=_value);
    bytes32 toF = getFoundId(_to);
    balancesF[fromF] = balancesF[fromF].sub(_value);
    balancesF[toF] = balancesF[toF].add(_value);
  }

  function transferFtoA  (address _from, address _to, uint _value) private {
    require(hasFName(_from) && foundP[getFoundId(_from)]==true);
    bytes32 fromF = getFoundId(_to);
    require(balancesF[fromF]>=_value);
    balancesF[fromF] = balancesF[fromF].sub(_value);
    balances[_to] = balances[_to].add(_value);
  }



  function transferPrivate(address _from, address _to, uint _value) private {
    bool fromF=useFoundP(_from);
    bool toF=useFoundP(_to);
    if (fromF && toF) {
      transferFtoF(_from, _to, _value);
    }
    if (fromF && !toF) {
      transferFtoA(_from, _to, _value);
    }
    if (!fromF && toF) {
      transferAtoF(_from, _to, _value);
    }
    if (!fromF && !toF) {
      transferAtoA(_from, _to, _value);
    }
  }


  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    transferPrivate(msg.sender, _to, _value);
  }




  /*
   * @dev Transfer tokens from one address to another
   * @dev If foundation support is enabled for user
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */


  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    require(_value>0);
    uint currentAllowance = allowance(_from, msg.sender);
    require(currentAllowance>=_value);
    uint newValue = currentAllowance.sub(_value);
    approvePrivate(_from, msg.sender, 0);
    approvePrivate(_from, msg.sender, newValue);
    transferPrivate(_from, _to, _value);
  }



  function approveFtoF(address _owner, address _spender, uint _value) private {
    require(hasFName(_owner) && foundP[getFoundId(_owner)]==true);
    require(hasFName(_spender) && foundP[getFoundId(_spender)]==true);
    bytes32 ownerF = getFoundId(_owner);
    bytes32 spenderF = getFoundId(_spender);
    if ((_value != 0) && (allowedFtoF[ownerF][spenderF] != 0)) revert();
    allowedFtoF[ownerF][spenderF] = _value;

  }
  function approveFtoA(address _owner, address _spender, uint _value) private {
    require(hasFName(_owner) && foundP[getFoundId(_owner)]==true);
    bytes32 ownerF = getFoundId(_owner);
    if ((_value != 0) && (allowedFtoA[ownerF][_spender] != 0)) revert();
    allowedFtoA[ownerF][_spender] = _value;
  }
  function approveAtoF(address _owner, address _spender, uint _value) private {
    require(hasFName(_spender) && foundP[getFoundId(_spender)]==true);
    bytes32 spenderF = getFoundId(_spender);
    if ((_value != 0) && (allowedAtoF[_owner][spenderF] != 0)) revert();
    allowedAtoF[_owner][spenderF] = _value;
  }
  function approveAtoA(address _owner, address _spender, uint _value) private {
    if ((_value != 0) && (allowedAtoA[_owner][_spender] != 0)) revert();
    allowedAtoA[_owner][_spender] = _value;
  }




  function approvePrivate(address _owner, address _spender, uint _value) private {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //    require(_value>0);

    //    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
   bool ownerF=useFoundP(_owner);
   bool spenderF=useFoundP(_spender);
   if (ownerF && spenderF) {
      approveFtoF(_owner, _spender, _value);
    }
    if (ownerF && !spenderF) {
      approveFtoA(_owner, _spender, _value);
    }
    if (!ownerF && spenderF) {
      approveAtoF(_owner, _spender, _value);
    }
    if (!ownerF && !spenderF) {
      approveAtoA(_owner, _spender, _value);
    }
  }

  /*
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */


  //what happens when an address becomes a foundationid? or the other way around?  approval won't exist anymore.

 function approve(address _spender, uint _value) {
   approvePrivate(msg.sender, _spender, _value);
  }



 function allowanceAtoA (address _owner, address _spender) private constant returns (uint remaining) {
   return allowedAtoA[_owner][_spender];
 }

 function allowanceAtoF (address _owner, address _spender) private constant returns (uint remaining) {
   require(hasFName(_spender) && foundP[getFoundId(_spender)]==true);
    bytes32 spenderF = getFoundId(_spender);
    return allowedAtoF[_owner][spenderF];
 }

 function allowanceFtoA (address _owner, address _spender) private constant returns (uint remaining) {
   require(hasFName(_owner) && foundP[getFoundId(_owner)]==true);
   bytes32 ownerF = getFoundId(_owner);
   return allowedFtoA[ownerF][_spender];
 }

 function allowanceFtoF (address _owner, address _spender) private constant returns (uint remaining) {
   require(hasFName(_owner) && foundP[getFoundId(_owner)]==true);
   require(hasFName(_spender) && foundP[getFoundId(_spender)]==true);
   bytes32 ownerF = getFoundId(_owner);
   bytes32 spenderF = getFoundId(_spender);
   return allowedFtoF[ownerF][spenderF];

 }


 /*
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    bool ownerF=useFoundP(_owner);
    bool spenderF=useFoundP(_spender);
    if (ownerF && spenderF) {
      allowanceFtoF(_owner, _spender);
    }
    if (ownerF && !spenderF) {
      allowanceFtoA(_owner, _spender);
    }
    if (!ownerF && spenderF) {
      allowanceAtoF(_owner, _spender);
    }
    if (!ownerF && !spenderF) {
      allowanceAtoA(_owner, _spender);
    }
  }

/*

  // must prevent any usage of addresses while in operation
  //

  /// this doesn't work as a loop because of unknown gas costs to loop



  /*
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */

  function balanceOf(address _owner) constant returns (uint balance) {
    if (hasFName(_owner) && foundP[getFoundId(_owner)]==true)  {
      bytes32 foundId=getFoundId(_owner);
      return balancesF[foundId];
      }
    else {
      return balances[_owner];
    }
  }
}
