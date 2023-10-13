//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EventRange {
  uint256 startedAt;
  uint256 endedAt;
}

library LibEventRange {
  /**
   * @dev Checks whether the event range is valid.
   */
  function valid(EventRange calldata range) internal pure returns (bool) {
    return range.startedAt <= range.endedAt;
  }

  /**
   * @dev Returns whether the current range is not yet started.
   */
  function isNotYetStarted(EventRange memory range) internal view returns (bool) {
    return block.timestamp < range.startedAt;
  }

  /**
   * @dev Returns whether the current range is ended or not.
   */
  function isEnded(EventRange memory range) internal view returns (bool) {
    return range.endedAt <= block.timestamp;
  }

  /**
   * @dev Returns whether the current block is in period.
   */
  function isInPeriod(EventRange memory range) internal view returns (bool) {
    return range.startedAt <= block.timestamp && block.timestamp < range.endedAt;
  }
}
