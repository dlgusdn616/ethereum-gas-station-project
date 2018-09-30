pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GasCheck{

    using SafeMath for uint256;

    address owner;
    string public gasStation;
    string public gasTankType;

    uint256 public beforeFuelAmount;

    uint256 public newFuelAmount;
    uint256 public EmptyingAmount;

    uint256 errorRange;

    bool public Fueling;
    bool public Emptying;

    event FuelingEvent(string _gasStationName, string _gasTankType ,uint256 _fillingFuelAmount, string _statusMessage);
    event CleaningEvent(string _gasStationName, string _gasTankType ,  uint256 _emptyingFuelAmount, string _statusMessage);
    event gasTankCheckedEvent(string _gasStationName, string _gasTankType, string _statusMessage);
    event abnormalTankCheckedEvent(string _gasStationName, string _gasTankType, string _statusMessage, uint256 _abnormalAmount);

    // Start Fueling -> Stop Fueling
    constructor(string _gasStationName, string _gasTankType) public {

        bytes memory isSationNameEmpty = bytes(_gasStationName);
        bytes memory isGasTypeEmpty = bytes(_gasTankType);

        if (isSationNameEmpty.length == 0 || isGasTypeEmpty.length == 0) {
            revert();
        }
        else {
            owner = msg.sender;
            gasStation = _gasStationName;
            gasTankType = _gasTankType;
            errorRange = 5;
        }

    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier notFueling {
        require(Fueling == false);
        _;
    }

    modifier notCleaning {
        require(Emptying == false);
        _;
    }

    function setErrorRange(uint256 _range) external onlyOwner { //Temporary function to set the error range.
        errorRange = _range;
    }

    function startFueling(uint256 _fillingFuelAmount) external onlyOwner {
        Fueling = true;
        newFuelAmount = _fillingFuelAmount;
        emit FuelingEvent(gasStation, gasTankType, _fillingFuelAmount, "Filling the gas tank");
    }
    
    function devEmptyFuel(uint256 _emptyingAmount) external onlyOwner{
        beforeFuelAmount = beforeFuelAmount.sub(_emptyingAmount);
    }

    function stopFueling() external onlyOwner {
        Fueling = false;
        beforeFuelAmount = beforeFuelAmount.add(newFuelAmount);
        newFuelAmount = 0;
        emit FuelingEvent(gasStation, gasTankType, beforeFuelAmount, "Finished filling the gas tank");
    }

    function startCleaning() external onlyOwner {
        Emptying = true;
        EmptyingAmount = beforeFuelAmount;
        beforeFuelAmount = 0;
        emit CleaningEvent(gasStation, gasTankType, EmptyingAmount ,"Started cleaning the tank");
    }

    // 청소 다하고 기름 채워넣었을 때
    function stopCleaning(uint256 _sensoredTankAmount) external onlyOwner { //When cleaning is over and the fuel has been recharged.

        Emptying = false;

        uint256 maxErrorAmount = EmptyingAmount.add(errorRange);
        uint256 minErrorAmount = EmptyingAmount.sub(errorRange);

        if(minErrorAmount<= _sensoredTankAmount && _sensoredTankAmount <= maxErrorAmount){
            beforeFuelAmount = EmptyingAmount;
        }

        emit CleaningEvent(gasStation, gasTankType, EmptyingAmount, "Finished cleaning the tank");
    }

    function checkGasTankAmount(uint256 _filledOutAmount, uint256 _sensoredTankAmount) public notFueling notCleaning {

        uint256 inputFuelAmount = _sensoredTankAmount.add(_filledOutAmount);

        uint256 maxErrorAmount = beforeFuelAmount.add(errorRange);
        uint256 minErrorAmount = beforeFuelAmount.sub(errorRange);

        if(minErrorAmount<= inputFuelAmount && inputFuelAmount <= maxErrorAmount){ //Allows the error range amount.
            beforeFuelAmount = _sensoredTankAmount;
            emit gasTankCheckedEvent(gasStation, gasTankType, "Tank has correct amount of gas");
        }

        else if(inputFuelAmount < minErrorAmount){ //The tank has less fuel than it should

            uint256 minAbnormalAmount = beforeFuelAmount.sub( _sensoredTankAmount);

            beforeFuelAmount = _sensoredTankAmount;
            emit abnormalTankCheckedEvent(gasStation, gasTankType, "Tank has lower amount of gas. Possible abnormal gas extraction occured", minAbnormalAmount );
        }

        else { //The tank has more fuel than it should.

            uint256 maxAbnormalAmount = _sensoredTankAmount.sub(beforeFuelAmount);

            beforeFuelAmount = _sensoredTankAmount;
            emit abnormalTankCheckedEvent(gasStation, gasTankType, "Tank has higher amount of gas. Possible abnormal liquid mixing occured", maxAbnormalAmount );

        }


    }

}