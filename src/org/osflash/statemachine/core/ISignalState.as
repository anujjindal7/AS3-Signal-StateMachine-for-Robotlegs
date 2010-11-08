package org.osflash.statemachine.core {
import org.osflash.signals.ISignal;

public interface ISignalState extends IState {
	function get entered():ISignal;

	function get enteringGuard():ISignal;

	function get exitingGuard():ISignal;

	function get cancelled():ISignal;

	function get tearDown():ISignal;
}
}