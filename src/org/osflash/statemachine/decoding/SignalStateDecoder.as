package org.osflash.statemachine.decoding {

import org.osflash.signals.ISignal;
import org.osflash.statemachine.base.BaseXMLStateDecoder;
import org.osflash.statemachine.core.ISignalState;
import org.osflash.statemachine.core.IState;
import org.osflash.statemachine.errors.UnregisteredSignalCommandError;
import org.osflash.statemachine.states.SignalState;
import org.robotlegs.core.IInjector;
import org.robotlegs.core.ISignalCommandMap;

public class SignalStateDecoder extends BaseXMLStateDecoder {
	protected var classBagMap:Array;
	protected var injector:IInjector;
	protected var signalCommandMap:ISignalCommandMap;

	public function SignalStateDecoder( fsm:XML, injector:IInjector, signalCommandMap:ISignalCommandMap ):void{
		this.injector = injector;
		this.signalCommandMap = signalCommandMap;
		super( fsm );
	}

	override public function decodeState( stateDef:Object ):IState{
		// Create State object
		var state:IState = getState( stateDef );
		decodeTransitions( state, stateDef );
		injectState( state, stateDef );
		return state;
	}

	public function addCommandClass( commandClass:Class ):Boolean{
		if( classBagMap == null ) classBagMap = [];
		if( hasClass( commandClass ) ) return false;
		classBagMap.push( new ClassBag( commandClass ) );
		return true;
	}

	public function hasClass( name:Object ):Boolean{
		return ( getClass( name ) != null );
	}

	protected function getState( stateDef:Object ):IState{
		return new SignalState( stateDef.@name.toString() );
	}

	protected function decodeTransitions( state:IState, stateDef:Object ):void{
		var transitions:XMLList = stateDef..transition as XMLList;
		for( var i:int; i < transitions.length(); i++ ){
			var transDef:XML = transitions[i];
			state.defineTrans( String( transDef.@action ), String( transDef.@target ) );
		}
	}

	protected function injectState( state:IState, stateDef:Object ):void{

		var inject:Boolean = ( stateDef.@inject.toString() == "true" );
		var exitingGuard:String = stateDef.@exitingGuard.toString();
		var enteringGuard:String = stateDef.@enteringGuard.toString();
		var entered:String = stateDef.@entered.toString();
		var tearDown:String = stateDef.@teardown.toString();
		var cancelled:String = stateDef.@cancelled.toString();

		if( inject )
			injector.mapValue( ISignalState, state, state.name );

		if( exitingGuard )
			mapSignalCommand( ISignalState( state ).exitingGuard, exitingGuard );

		if( enteringGuard )
			mapSignalCommand( ISignalState( state ).enteringGuard, enteringGuard );

		if( entered )
			mapSignalCommand( ISignalState( state ).entered, entered );

		if( tearDown )
			mapSignalCommand( ISignalState( state ).tearDown, tearDown );

		if( cancelled )
			mapSignalCommand( ISignalState( state ).cancelled, cancelled );

	}

	protected function getClass( name:Object ):Class{
		for each ( var cb:ClassBag in classBagMap ){
			if( cb.equals( name ) ) return cb.payload;
		}
		return null;
	}

	private function mapSignalCommand( signal:ISignal, commandClassName:String ):void{
		var c:Class = getClass( commandClassName );
		if( c == null )throw new UnregisteredSignalCommandError( commandClassName );
		signalCommandMap.mapSignal( signal, c );
	}

}
}

import flash.utils.describeType;

/**
 * Wrapper class for a Class reference.
 */
internal class ClassBag {

	/**
	 * the package of the wrapped Class
	 */
	public var pkg:String;

	/**
	 * the name of the wrapped Class
	 */
	public var name:String;

	/**
	 * the Class referance
	 */
	internal var payload:Class;

	/**
	 * @param c the Class to be wrapped
	 */
	public function ClassBag( c:Class ):void{
		payload = c;
		describeClass( c );
	}

	public function toString():String{
		return pkg + "." + name;
	}

	/**
	 * Evaluates the equality of the value passed with the wrapped Class.
	 * can pass the full qualified class name ( my.full.package.Class or my.full.package::Class )
	 * or just the name
	 * or an instance of the Class ref itself
	 * @param value item to evaluate against
	 * @return the result
	 *
	 */
	public function equals( value:Object ):Boolean{
		return (( value.toString() == pkg + "." + name ) || ( value.toString() == pkg + "::" + name ) || ( value.toString() == name ) || ( value == payload )						    );
	}

	/**
	 * Destroys the ClassBag
	 */
	public function destroy():void{
		payload = null;
		name = null;
		pkg = null;
	}

	/**
	 * @private
	 */
	private function describeClass( c:Class ):void{
		var description:XML = describeType( c );
		var split:Array = description.@name.toString().split( "::" );
		pkg = String( split[0] );
		name = String( split[1] );
	}
}
