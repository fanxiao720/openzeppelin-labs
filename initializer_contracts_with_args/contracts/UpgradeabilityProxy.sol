pragma solidity ^0.4.24;

import './Proxy.sol';
import 'openzeppelin-solidity/contracts/AddressUtils.sol';

/**
 * @title UpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "org.zeppelinos.proxy.implementation", and is
   * validated in the constructor.
   */
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

  /**
   * @dev Contract constructor.
   * @param _implementation Address of the initial implementation.
   */
  constructor(address _constructor, address _implementation, bytes _args) public {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));

    _runConstructor(_constructor, _args);

    _setImplementation(_implementation);
  }

  function _runConstructor(address _constructor, bytes _args) private {
    address _constructorWithArgs;

    uint256 args_size = _args.length;

    assembly {
      let args := add(_args, 0x20)

      let ctor_size := extcodesize(_constructor)
      let size := add(ctor_size, args_size)

      let ctor := mload(0x40)
      mstore(0x40, add(ctor, size))

      extcodecopy(_constructor, ctor, 0, ctor_size)

      let ctor_args := add(ctor, ctor_size)

      for { let i := 0 } lt(i, args_size) { i := add(i, 0x20) } {
        mstore(add(ctor_args, i), mload(add(args, i)))
      }

      _constructorWithArgs := create(0, ctor, size)
    }

    require(_constructorWithArgs.delegatecall());
  }

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) private {
    require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}
