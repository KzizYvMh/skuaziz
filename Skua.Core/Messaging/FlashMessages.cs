namespace Skua.Core.Messaging;

public sealed record FlashErrorMessage(Exception Exception, string Function, params object[] Args);
