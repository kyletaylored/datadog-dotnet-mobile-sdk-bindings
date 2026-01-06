namespace Datadog.iOS.ObjC
{
	public enum DDBatchProcessingLevel
	{
		Low = 0,
		Medium = 1,
		High = 2
	}

	public enum DDBatchSize
	{
		Small = 0,
		Medium = 1,
		Large = 2
	}

	public enum DDCoreLoggerLevel
	{
		Debug = 0,
		Warn = 1,
		Error = 2,
		Critical = 3
	}

	public enum DDInjectEncoding
	{
		Multiple = 0,
		Single = 1
	}

	public enum DDLogEventInterface
	{
		Wifi = 0,
		WiredEthernet = 1,
		Cellular = 2,
		Loopback = 3,
		Other = 4
	}

	public enum DDLogEventRadioAccessTechnology
	{
		Gprs = 0,
		Edge = 1,
		Wcdma = 2,
		Hsdpa = 3,
		Hsupa = 4,
		CDMA1x = 5,
		CDMAEVDORev0 = 6,
		CDMAEVDORevA = 7,
		CDMAEVDORevB = 8,
		Ehrpd = 9,
		Lte = 10,
		Unknown = 11
	}

	public enum DDLogEventReachability
	{
		Yes = 0,
		Maybe = 1,
		No = 2
	}

	public enum DDLogEventStatus
	{
		Debug = 0,
		Info = 1,
		Notice = 2,
		Warn = 3,
		Error = 4,
		Critical = 5,
		Emergency = 6
	}

	public enum DDLogLevel
	{
		Debug = 0,
		Info = 1,
		Notice = 2,
		Warn = 3,
		Error = 4,
		Critical = 5
	}

	public enum DDRUMActionEventActionActionType
	{
		Custom = 0,
		Click = 1,
		Tap = 2,
		Scroll = 3,
		Swipe = 4,
		ApplicationStart = 5,
		Back = 6
	}

	public enum DDRUMActionEventActionFrustrationFrustrationType
	{
		RageClick = 0,
		DeadClick = 1,
		ErrorClick = 2,
		RageTap = 3,
		ErrorTap = 4
	}

	public enum DDRUMActionEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMActionEventDDActionNameSource
	{
		None = 0,
		CustomAttribute = 1,
		MaskPlaceholder = 2,
		StandardAttribute = 3,
		TextContent = 4,
		MaskDisallowed = 5,
		Blank = 6
	}

	public enum DDRUMActionEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMActionEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMActionEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMActionEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMActionEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMActionEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMActionEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMActionEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMActionType
	{
		Tap = 0,
		Scroll = 1,
		Swipe = 2,
		Custom = 3
	}

	public enum DDRUMErrorEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMErrorEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMErrorEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMErrorEventErrorCSPDisposition
	{
		None = 0,
		Enforce = 1,
		Report = 2
	}

	public enum DDRUMErrorEventErrorCategory
	{
		None = 0,
		Anr = 1,
		AppHang = 2,
		Exception = 3,
		WatchdogTermination = 4,
		MemoryWarning = 5
	}

	public enum DDRUMErrorEventErrorCausesSource
	{
		Network = 0,
		Source = 1,
		Console = 2,
		Logger = 3,
		Agent = 4,
		Webview = 5,
		Custom = 6,
		Report = 7
	}

	public enum DDRUMErrorEventErrorHandling
	{
		None = 0,
		Handled = 1,
		Unhandled = 2
	}

	public enum DDRUMErrorEventErrorResourceProviderProviderType
	{
		None = 0,
		Ad = 1,
		Advertising = 2,
		Analytics = 3,
		Cdn = 4,
		Content = 5,
		CustomerSuccess = 6,
		FirstParty = 7,
		Hosting = 8,
		Marketing = 9,
		Other = 10,
		Social = 11,
		TagManager = 12,
		Utility = 13,
		Video = 14
	}

	public enum DDRUMErrorEventErrorResourceRUMMethod
	{
		Post = 0,
		Get = 1,
		Head = 2,
		Put = 3,
		Delete = 4,
		Patch = 5,
		Trace = 6,
		Options = 7,
		Connect = 8
	}

	public enum DDRUMErrorEventErrorSource
	{
		Network = 0,
		Source = 1,
		Console = 2,
		Logger = 3,
		Agent = 4,
		Webview = 5,
		Custom = 6,
		Report = 7
	}

	public enum DDRUMErrorEventErrorSourceType
	{
		None = 0,
		Android = 1,
		Browser = 2,
		Ios = 3,
		ReactNative = 4,
		Flutter = 5,
		Roku = 6,
		Ndk = 7,
		IosIl2cpp = 8,
		NdkIl2cpp = 9
	}

	public enum DDRUMErrorEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMErrorEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMErrorEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMErrorEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMErrorEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMErrorEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMErrorSource
	{
		Source = 0,
		Network = 1,
		Webview = 2,
		Console = 3,
		Custom = 4
	}

	public enum DDRUMLongTaskEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMLongTaskEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMLongTaskEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMLongTaskEventLongTaskEntryType
	{
		None = 0,
		LongTask = 1,
		LongAnimationFrame = 2
	}

	public enum DDRUMLongTaskEventLongTaskScriptsInvokerType
	{
		None = 0,
		UserCallback = 1,
		EventListener = 2,
		ResolvePromise = 3,
		RejectPromise = 4,
		ClassicScript = 5,
		ModuleScript = 6
	}

	public enum DDRUMLongTaskEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMLongTaskEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMLongTaskEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMLongTaskEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMLongTaskEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMLongTaskEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMMethod
	{
		Post = 0,
		Get = 1,
		Head = 2,
		Put = 3,
		Delete = 4,
		Patch = 5,
		Connect = 6,
		Trace = 7,
		Options = 8
	}

	public enum DDRUMResourceEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMResourceEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMResourceEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMResourceEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMResourceEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMResourceEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMResourceEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMResourceEventResourceDeliveryType
	{
		None = 0,
		Cache = 1,
		NavigationalPrefetch = 2,
		Other = 3
	}

	public enum DDRUMResourceEventResourceGraphqlOperationType
	{
		Query = 0,
		Mutation = 1,
		Subscription = 2
	}

	public enum DDRUMResourceEventResourceProviderProviderType
	{
		None = 0,
		Ad = 1,
		Advertising = 2,
		Analytics = 3,
		Cdn = 4,
		Content = 5,
		CustomerSuccess = 6,
		FirstParty = 7,
		Hosting = 8,
		Marketing = 9,
		Other = 10,
		Social = 11,
		TagManager = 12,
		Utility = 13,
		Video = 14
	}

	public enum DDRUMResourceEventResourceRUMMethod
	{
		None = 0,
		Post = 1,
		Get = 2,
		Head = 3,
		Put = 4,
		Delete = 5,
		Patch = 6,
		Trace = 7,
		Options = 8,
		Connect = 9
	}

	public enum DDRUMResourceEventResourceRenderBlockingStatus
	{
		None = 0,
		Blocking = 1,
		NonBlocking = 2
	}

	public enum DDRUMResourceEventResourceResourceType
	{
		Document = 0,
		Xhr = 1,
		Beacon = 2,
		Fetch = 3,
		Css = 4,
		Js = 5,
		Image = 6,
		Font = 7,
		Media = 8,
		Other = 9,
		Native = 10
	}

	public enum DDRUMResourceEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMResourceEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMResourceType
	{
		Image = 0,
		Xhr = 1,
		Beacon = 2,
		Css = 3,
		Document = 4,
		Fetch = 5,
		Font = 6,
		Js = 7,
		Media = 8,
		Other = 9,
		Native = 10
	}

	public enum DDRUMViewEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMViewEventDDPageStatesState
	{
		Active = 0,
		Passive = 1,
		Hidden = 2,
		Frozen = 3,
		Terminated = 4
	}

	public enum DDRUMViewEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMViewEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMViewEventPrivacyReplayLevel
	{
		Allow = 0,
		Mask = 1,
		MaskUserInput = 2
	}

	public enum DDRUMViewEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMViewEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMViewEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMViewEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMViewEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMViewEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMViewEventViewLoadingType
	{
		None = 0,
		InitialLoad = 1,
		RouteChange = 2,
		ActivityDisplay = 3,
		ActivityRedisplay = 4,
		FragmentDisplay = 5,
		FragmentRedisplay = 6,
		ViewControllerDisplay = 7,
		ViewControllerRedisplay = 8
	}

	public enum DDRUMVitalEventContainerSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Roku = 5,
		Unity = 6,
		KotlinMultiplatform = 7
	}

	public enum DDRUMVitalEventDDSessionPlan
	{
		None = 0,
		Plan1 = 1,
		Plan2 = 2
	}

	public enum DDRUMVitalEventDDSessionRUMSessionPrecondition
	{
		None = 0,
		UserAppLaunch = 1,
		InactivityTimeout = 2,
		MaxDuration = 3,
		BackgroundLaunch = 4,
		Prewarm = 5,
		FromNonInteractiveSession = 6,
		ExplicitStop = 7
	}

	public enum DDRUMVitalEventRUMConnectivityEffectiveType
	{
		None = 0,
		Slow2g = 1,
		EffectiveType2g = 2,
		EffectiveType3g = 3,
		EffectiveType4g = 4
	}

	public enum DDRUMVitalEventRUMConnectivityInterfaces
	{
		None = 0,
		Bluetooth = 1,
		Cellular = 2,
		Ethernet = 3,
		Wifi = 4,
		Wimax = 5,
		Mixed = 6,
		Other = 7,
		Unknown = 8,
		InterfacesNone = 9
	}

	public enum DDRUMVitalEventRUMConnectivityStatus
	{
		Connected = 0,
		NotConnected = 1,
		Maybe = 2
	}

	public enum DDRUMVitalEventRUMDeviceRUMDeviceType
	{
		Mobile = 0,
		Desktop = 1,
		Tablet = 2,
		Tv = 3,
		GamingConsole = 4,
		Bot = 5,
		Other = 6
	}

	public enum DDRUMVitalEventSessionRUMSessionType
	{
		User = 0,
		Synthetics = 1,
		CiTest = 2
	}

	public enum DDRUMVitalEventSource
	{
		None = 0,
		Android = 1,
		Ios = 2,
		Browser = 3,
		Flutter = 4,
		ReactNative = 5,
		Roku = 6,
		Unity = 7,
		KotlinMultiplatform = 8
	}

	public enum DDRUMVitalEventVitalVitalType
	{
		DDRUMVitalEventVitalVitalTypeDuration = 0
	}

	public enum DDRUMVitalsFrequency
	{
		Frequent = 0,
		Average = 1,
		Rare = 2,
		Never = 3
	}

	public enum DDSDKVerbosityLevel
	{
		None = 0,
		Debug = 1,
		Warn = 2,
		Error = 3,
		Critical = 4
	}

	public enum DDTelemetryConfigurationEventSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Unity = 5,
		KotlinMultiplatform = 6
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationSelectedTracingPropagators
	{
		None = 0,
		Datadog = 1,
		B3 = 2,
		B3multi = 3,
		Tracecontext = 4
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationSessionPersistence
	{
		None = 0,
		LocalStorage = 1,
		Cookie = 2
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationTraceContextInjection
	{
		None = 0,
		All = 1,
		Sampled = 2
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationTrackFeatureFlagsForEvents
	{
		None = 0,
		Vital = 1,
		Resource = 2,
		Action = 3,
		LongTask = 4
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationTrackingConsent
	{
		None = 0,
		Granted = 1,
		NotGranted = 2,
		Pending = 3
	}

	public enum DDTelemetryConfigurationEventTelemetryConfigurationViewTrackingStrategy
	{
		None = 0,
		ActivityViewTrackingStrategy = 1,
		FragmentViewTrackingStrategy = 2,
		MixedViewTrackingStrategy = 3,
		NavigationViewTrackingStrategy = 4
	}

	public enum DDTelemetryDebugEventSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Unity = 5,
		KotlinMultiplatform = 6
	}

	public enum DDTelemetryErrorEventSource
	{
		Android = 0,
		Ios = 1,
		Browser = 2,
		Flutter = 3,
		ReactNative = 4,
		Unity = 5,
		KotlinMultiplatform = 6
	}

	public enum DDTraceContextInjection
	{
		All = 0,
		Sampled = 1
	}

	public enum DDUploadFrequency
	{
		Frequent = 0,
		Average = 1,
		Rare = 2
	}
}
