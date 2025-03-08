class ZGGComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StaticMeshComponent GeneratorMesh;
var float mGeneratorRadius;
var float mGravityImpulse;
var ParticleSystem mZeroGravTemplate;
var SoundCue mStartZeroGravSound;
var SoundCue mStopZeroGravSound;
var bool mIsHPressed;
var bool mIsGPressed;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		generatorMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( generatorMesh, 'hairSocket' );
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	if(PCOwner != gMe.Controller)
		return;

	if( keyState == KS_Down )
	{
		if(newKey == 'G' || newKey == 'XboxTypeS_RightShoulder')
		{
			mIsGPressed=true;
			ChangeGravity(0.f);
		}

		if(newKey == 'H' || newKey == 'XboxTypeS_LeftShoulder')
		{
			mIsHPressed=true;
			ChangeGravity(1.f);
		}
	}
	else if( keyState == KS_Up )
	{
		if(newKey == 'G' || newKey == 'XboxTypeS_RightShoulder')
		{
			mIsGPressed=false;
		}

		if(newKey == 'H' || newKey == 'XboxTypeS_LeftShoulder')
		{
			mIsHPressed=false;
		}
	}
}

function ChangeGravity(float newGravity)
{
	local Actor act;
	local GGPawn gpawn;
	local GGInterpActor interpact;
	local vector direction, vel;
	local MeshComponent meshComp;
	local ParticleSystemComponent zeroGravPSC;
	//Moon gravity easter egg
	if(mIsGPressed && mIsHPressed)
	{
		newGravity=0.2f;
	}
	//Zero grav particle
	zeroGravPSC = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(mZeroGravTemplate, gMe.mesh, 'hairSocket', true);
	zeroGravPSC.bAutoActivate = true;
	gMe.PlaySound(newGravity==1.f?mStopZeroGravSound:mStartZeroGravSound);

	foreach myMut.OverlappingActors(class'Actor', act, mGeneratorRadius, gMe.Location)
	{
		if((GGInterpActor(act) != none && act.Base != none) || act.bHidden)//Don't affect fixed and invisible items
			continue;
		//myMut.WorldInfo.Game.Broadcast(myMut, act $ " Physics=" $ act.Physics);
		gpawn=GGPawn(act);
		interpact=GGInterpActor(act);
		direction.X=RandRange( -1.0f, 1.0f );
		direction.Y=RandRange( -1.0f, 1.0f );
		direction.Z=RandRange( -1.0f, 1.0f );

		if(gpawn != none)
		{
			gpawn.CustomGravityScaling=newGravity;
			if(GGNpc(gpawn) != none)
			{
				GGNpc(gpawn).SetRagdoll(true);
				if(newGravity == 0.f)
				{
					GGNpc(gpawn).DisableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
				}
				else
				{
					GGNpc(gpawn).EnableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
				}
			}

			/*if(gpawn.mIsRagdoll && newGravity != 1.f)
			{
				gpawn.Mesh.AddForce(Normal(direction) * 1000);
			}*/
			meshComp=gpawn.mesh;
		}
		else
		{
			meshComp=MeshComponent(act.CollisionComponent);
		}

		if(interpact != none)
		{
			if(newGravity == 1.f)
			{
				interpact.SetPhysics(PHYS_Interpolating);
			}
			else
			{
				interpact.SetPhysics(PHYS_RigidBody);
			}
		}

		meshComp.BodyInstance.CustomGravityFactor=newGravity;
		if(newGravity == 0.f)
		{
			vel=meshComp.GetRBLinearVelocity();
			vel += Normal(direction) * mGravityImpulse;
			meshComp.SetRBLinearVelocity(vel);
		}
	}
}

defaultproperties
{
	mGeneratorRadius=1000.f
	mGravityImpulse=10.f

	mZeroGravTemplate=ParticleSystem'Zombie_Particles.Particles.Mind_Control_Burst2'
	mStartZeroGravSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Wheel_Of_Time_Time_Resumed_Cue'
	mStopZeroGravSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Wheel_Of_Time_Time_Stopped_Cue'

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'UFO.Mesh.UFO_01'
		Scale=0.01f
		Translation=(X=0.f, Y=5.f, Z=10.f)
	End Object
	generatorMesh=StaticMeshComp1
}