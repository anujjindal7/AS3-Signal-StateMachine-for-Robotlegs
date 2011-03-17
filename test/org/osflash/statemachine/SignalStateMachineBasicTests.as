package org.osflash.statemachine {
import flexunit.framework.Assert;

import org.osflash.statemachine.core.IFSMController;
import org.osflash.statemachine.core.ISignalState;
import org.robotlegs.adapters.SwiftSuspendersInjector;
import org.robotlegs.adapters.SwiftSuspendersReflector;
import org.robotlegs.base.GuardedSignalCommandMap;
import org.robotlegs.core.IGuardedSignalCommandMap;
import org.robotlegs.core.IInjector;
import org.robotlegs.core.IReflector;

public class SignalStateMachineBasicTests {


    private var injector:IInjector;
    private var reflector:IReflector;
    private var signalCommandMap:IGuardedSignalCommandMap;
    private var fsmInjector:SignalFSMInjector;

    [Before]
    public function before():void {
        injector = new SwiftSuspendersInjector();
        reflector = new SwiftSuspendersReflector();
        signalCommandMap = new GuardedSignalCommandMap(injector, reflector);
        fsmInjector = new SignalFSMInjector(injector, signalCommandMap);
        fsmInjector.initiate(FSM);
        fsmInjector.inject();
        fsmInjector.destroy();

    }

    [After]
    public function after():void {
        injector = null;
        reflector = null;
        signalCommandMap = null;
        fsmInjector = null;
    }


    [Test]
    public function fsmController_is_mapped():void {
        Assert.assertTrue(injector.hasMapping(IFSMController));
    }

    [Test]
    public function fsm_is_initialised():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        Assert.assertEquals(STARTING, fsmController.currentStateName);
    }

    [Test]
    public function STARTING_state_should_not_be_injected():void {
        Assert.assertFalse(injector.hasMapping(ISignalState, STARTING));
    }

    [Test]
    public function advance_to_next_state():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        fsmController.action(NEXT);   // to SECOND
        Assert.assertEquals(SECOND, fsmController.currentStateName);
    }

    [Test]
    public function advance_to_SECOND_state_with_payload_testing_SECOND_onEntered_arguments():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var transitionPayload:Object = {};
        var wasOnEnteredCalled:Boolean;
        var onEntered:Function = function (payload:Object):void {
            Assert.assertStrictlyEquals(transitionPayload, payload);
            wasOnEnteredCalled = true;
        };
        state.entered.addOnce(onEntered);
        fsmController.action(NEXT, transitionPayload);     // to SECOND
        Assert.assertTrue(wasOnEnteredCalled);

    }

    [Test]
    public function advance_to_SECOND_state_with_payload_testing_SECOND_enteringGuard_arguments():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var transitionPayload:Object = {};
        var wasOnEnteringGuardCalled:Boolean;
        var onEnteringGuard:Function = function (payload:Object):void {
            Assert.assertStrictlyEquals(transitionPayload, payload);
            wasOnEnteringGuardCalled = true;
        };
        state.enteringGuard.addOnce(onEnteringGuard);

        fsmController.action(NEXT, transitionPayload);  // toSECOND

        Assert.assertTrue(wasOnEnteringGuardCalled);

    }

    [Test]
    public function advance_to_THIRD_state_with_payload_testing_SECOND_exitingGuard_arguments():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var transitionPayload:Object = {};
        var wasOnExitingGuardCalled:Boolean;
        var onEnteringGuard:Function = function (payload:Object):void {
            Assert.assertStrictlyEquals(transitionPayload, payload);
            wasOnExitingGuardCalled = true;
        };
        state.exitingGuard.addOnce(onEnteringGuard);

        fsmController.action(NEXT, transitionPayload); // to SECOND
        fsmController.action(NEXT, transitionPayload); // to THIRD

        Assert.assertTrue(wasOnExitingGuardCalled);

    }

    [Test]
    public function cancel_transition_from_SECOND_state_exitingGuard_testing_SECOND_cancellation_arguments():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var cancellationReason:String = "testingReason";
        var cancellationPayload:Object = {};
        var wasOnCancellationCalled:Boolean;

        var onExitingGuard:Function = function (payload:Object):void {
            fsmController.cancel(cancellationReason, cancellationPayload);
        };
        state.exitingGuard.addOnce(onExitingGuard);

        var onCancellation:Function = function (reason:String, payload:Object):void {
            Assert.assertEquals( cancellationReason, reason );
            Assert.assertStrictlyEquals( cancellationPayload, payload );
            wasOnCancellationCalled = true;
        };
        state.cancelled.addOnce(onCancellation);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

        Assert.assertTrue( wasOnCancellationCalled);


    }

    [Test]
    public function cancel_transition_from_THIRD_state_enteringGuard_testing_SECOND_cancellation_arguments():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var secondState:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var thirdState:ISignalState = injector.getInstance(ISignalState, THIRD) as ISignalState;
        var cancellationReason:String = "testingReason";
        var cancellationPayload:Object = {};
        var wasOnCancellationCalled:Boolean;

        var onEnteringGuard:Function = function (payload:Object):void {
            fsmController.cancel(cancellationReason, cancellationPayload);
        };
        thirdState.enteringGuard.addOnce(onEnteringGuard);

        var onCancellation:Function = function (reason:String, payload:Object):void {
            Assert.assertEquals( cancellationReason, reason );
            Assert.assertStrictlyEquals( cancellationPayload, payload );
            wasOnCancellationCalled = true;
        };
        secondState.cancelled.addOnce(onCancellation);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

        Assert.assertTrue( wasOnCancellationCalled );


    }




    [Test]
    public function advance_with_non_declared_transition():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        fsmController.action(NON_DECLARED_TRANSITION);
        Assert.assertEquals(STARTING, fsmController.currentStateName);
    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function advance_to_non_declared_target_state():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        fsmController.action(TO_NON_DECLARED_TARGET);

    }

    [Test]
    public function SECOND_and_THIRD_state_should_be_injected():void {
        Assert.assertTrue("SECOND state should be injected", injector.hasMapping(ISignalState, SECOND));
        Assert.assertTrue("THIRD state should be injected", injector.hasMapping(ISignalState, THIRD));
    }

    [Test]
    public function cancel_transition_from_SECOND_state_exitingGuard():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onExitingGuard:Function = function (payload:Object):void {
            fsmController.cancel("testing");
        };
        state.exitingGuard.addOnce(onExitingGuard);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

        Assert.assertEquals(SECOND, fsmController.currentStateName);


    }

    [Test]
    public function cancel_transition_from_THIRD_state_enteringGuard():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, THIRD) as ISignalState;
        var onEnteringGuard:Function = function (payload:Object):void {
            fsmController.cancel("testing");
        };
        state.enteringGuard.addOnce(onEnteringGuard);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

        Assert.assertEquals(SECOND, fsmController.currentStateName);

    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function cancel_transition_from_SECOND_state_tearDown():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onTearDown:Function = function ():void {
            fsmController.cancel("testing");
        };
        state.tearDown.addOnce(onTearDown);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function cancel_transition_from_THIRD_state_entered():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, THIRD) as ISignalState;
        var onEntered:Function = function (payload:Object):void {
            fsmController.cancel("testing");
        };
        state.entered.addOnce(onEntered);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function cancel_transition_from_SECOND_state_cancelled():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onExitingGuard:Function = function (payload:Object):void {
            fsmController.cancel("testing");
        };
        var onCancelled:Function = function (reason:String, payload:Object):void {
            fsmController.cancel("testing");
        };
        state.exitingGuard.addOnce(onExitingGuard);
        state.cancelled.addOnce(onCancelled);

        fsmController.action(NEXT);  // to SECOND
        fsmController.action(NEXT);  // to THIRD

    }

    [Test]
    public function invoke_transition_from_SECOND_state_entered():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onEntered:Function = function (payload:Object):void {
            fsmController.action(NEXT);    // to THIRD
        };
        state.entered.addOnce(onEntered);
        fsmController.action(NEXT);   // to SECOND

        Assert.assertEquals(THIRD, fsmController.currentStateName);
    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function invoke_transition_from_SECOND_state_enteringGuard():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onEnteringGuard:Function = function (payload:Object):void {
            fsmController.action(NEXT);     // to THIRD
        };
        state.enteringGuard.addOnce(onEnteringGuard);
        fsmController.action(NEXT);     // to SECOND

    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function invoke_transition_from_SECOND_state_exitingGuard():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onExitingGuard:Function = function (payload:Object):void {
            fsmController.action(NEXT);
        };
        state.enteringGuard.addOnce(onExitingGuard);
        fsmController.action(NEXT);    // to SECOND
        fsmController.action(NEXT);     // to THIRD

    }

    [Test(expected="org.osflash.statemachine.errors.StateTransitionError")]
    public function invoke_transition_from_SECOND_state_tearDown():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onTearDown:Function = function ():void {
            fsmController.action(NEXT);
        };
        state.tearDown.addOnce(onTearDown);
        fsmController.action(NEXT);    // to SECOND
        fsmController.action(NEXT);    // to THIRD

    }

    [Test]
    public function invoke_transition_from_SECOND_state_cancelled():void {
        var fsmController:IFSMController = injector.getInstance(IFSMController) as IFSMController;
        var state:ISignalState = injector.getInstance(ISignalState, SECOND) as ISignalState;
        var onExitingGuard:Function = function (payload:Object):void {
            fsmController.cancel("testing");
        };
        var onCancelled:Function = function (reason:String, payload:Object):void {
            fsmController.action(NEXT); // to THIRD
        };
        state.exitingGuard.addOnce(onExitingGuard);
        state.cancelled.addOnce(onCancelled);

        fsmController.action(NEXT); // to SECOND
        fsmController.action(NEXT); // to THIRD (but cancelled)

        Assert.assertEquals(THIRD, fsmController.currentStateName);

    }


    private static const STARTING:String = "starting";
    private static const SECOND:String = "second";
    private static const THIRD:String = "third";
    private static const NON_DECLARED_TARGET:String = "nonDeclaredTarget";

    private static const NEXT:String = "next";
    private static const NON_DECLARED_TRANSITION:String = "nonDeclaredTransition";
    private static const TO_NON_DECLARED_TARGET:String = "toNonDeclaredTarget";

    private var FSM:XML =
            <fsm initial={STARTING}>
                <state  name={STARTING}>
                    <transition action={NEXT} target={SECOND}/>
                    <transition action={TO_NON_DECLARED_TARGET} target={NON_DECLARED_TARGET}/>
                </state>

                <state name={SECOND} inject="true">
                    <transition action={NEXT} target={THIRD}/>
                </state>

                <state name={THIRD} inject="true">
                    <transition action={NEXT} target={THIRD}/>
                </state>
            </fsm>;


}
}