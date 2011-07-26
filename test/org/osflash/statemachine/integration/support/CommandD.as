package org.osflash.statemachine.integration.support {

import org.osflash.statemachine.core.IFSMProperties;
import org.osflash.statemachine.core.IPayload;

public class CommandD {
    [Inject]
    public var resultsRegistery:IResultRegistable;

    [Inject]
    public var payload:IPayload;

     [Inject]
    public var fsmProperties:IFSMProperties;

    public function execute():void {
        const state:String = fsmProperties.currentStateName.split("/")[1];
        const phase:String = fsmProperties.transitionPhase.identifier.split("/")[1];
        resultsRegistery.pushResult( "CommandD:: " + state + " | " + phase + " | " + payload.body );
    }
}
}