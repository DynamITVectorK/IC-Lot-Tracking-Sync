/// <summary>
/// Manages OAuth2 client credentials for cross-tenant IC Lot Tracking Sync API calls.
/// Secrets are stored exclusively in IsolatedStorage (scope: Company) and are never
/// written to any BC table field.
/// </summary>
codeunit 50306 "ICLTS OAuth Mgt."
{
    Access = Public;

    var
        StorageKeyPrefixTok: Label 'ICLTS_OAuth_', Locked = true;
        SecretSuffixTok: Label '_Secret', Locked = true;
        TenantIdSuffixTok: Label '_TenantId', Locked = true;
        ClientIdSuffixTok: Label '_ClientId', Locked = true;
        TokenUrlSuffixTok: Label '_TokenUrl', Locked = true;

    // ──────────────────────────────────────────────────────────────────────────
    // Storage helpers
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Persists the OAuth2 client secret for the given IC partner into IsolatedStorage
    /// with Company scope.  The secret is never written to any BC table field.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code used as part of the storage key.</param>
    /// <param name="ClientSecret">The client secret value to store.</param>
    procedure SetClientSecret(ICPartnerCode: Code[20]; ClientSecret: SecretText)
    begin
        IsolatedStorage.Set(StorageKeyPrefixTok + ICPartnerCode + SecretSuffixTok, ClientSecret, DataScope::Company);
    end;

    /// <summary>
    /// Retrieves the OAuth2 client secret for the given IC partner from IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code identifying the secret.</param>
    /// <param name="ClientSecret">Output — the secret value; empty if not found.</param>
    /// <returns>True if the secret was found; false otherwise.</returns>
    procedure GetClientSecret(ICPartnerCode: Code[20]; var ClientSecret: SecretText): Boolean
    begin
        exit(IsolatedStorage.Get(StorageKeyPrefixTok + ICPartnerCode + SecretSuffixTok, DataScope::Company, ClientSecret));
    end;

    /// <summary>
    /// Stores the Azure AD tenant ID for the given IC partner in IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code used as part of the storage key.</param>
    /// <param name="TenantId">The Azure AD tenant ID of the partner tenant.</param>
    procedure SetTenantId(ICPartnerCode: Code[20]; TenantId: Text[250])
    begin
        IsolatedStorage.Set(StorageKeyPrefixTok + ICPartnerCode + TenantIdSuffixTok, TenantId, DataScope::Company);
    end;

    /// <summary>
    /// Retrieves the Azure AD tenant ID for the given IC partner from IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code identifying the entry.</param>
    /// <param name="TenantId">Output — the stored tenant ID; empty if not found.</param>
    /// <returns>True if the entry was found; false otherwise.</returns>
    procedure GetTenantId(ICPartnerCode: Code[20]; var TenantId: Text[250]): Boolean
    var
        StoredValue: Text;
    begin
        if IsolatedStorage.Get(StorageKeyPrefixTok + ICPartnerCode + TenantIdSuffixTok, DataScope::Company, StoredValue) then begin
            TenantId := CopyStr(StoredValue, 1, MaxStrLen(TenantId));
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Stores the OAuth2 client ID for the given IC partner in IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code used as part of the storage key.</param>
    /// <param name="ClientId">The OAuth2 client (application) ID.</param>
    procedure SetClientId(ICPartnerCode: Code[20]; ClientId: Text[250])
    begin
        IsolatedStorage.Set(StorageKeyPrefixTok + ICPartnerCode + ClientIdSuffixTok, ClientId, DataScope::Company);
    end;

    /// <summary>
    /// Retrieves the OAuth2 client ID for the given IC partner from IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code identifying the entry.</param>
    /// <param name="ClientId">Output — the stored client ID; empty if not found.</param>
    /// <returns>True if the entry was found; false otherwise.</returns>
    procedure GetClientId(ICPartnerCode: Code[20]; var ClientId: Text[250]): Boolean
    var
        StoredValue: Text;
    begin
        if IsolatedStorage.Get(StorageKeyPrefixTok + ICPartnerCode + ClientIdSuffixTok, DataScope::Company, StoredValue) then begin
            ClientId := CopyStr(StoredValue, 1, MaxStrLen(ClientId));
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Stores the OAuth2 token endpoint URL for the given IC partner in IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code used as part of the storage key.</param>
    /// <param name="TokenUrl">The full OAuth2 token endpoint URL.</param>
    procedure SetTokenUrl(ICPartnerCode: Code[20]; TokenUrl: Text[250])
    begin
        IsolatedStorage.Set(StorageKeyPrefixTok + ICPartnerCode + TokenUrlSuffixTok, TokenUrl, DataScope::Company);
    end;

    /// <summary>
    /// Retrieves the OAuth2 token endpoint URL for the given IC partner from IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner code identifying the entry.</param>
    /// <param name="TokenUrl">Output — the stored token URL; empty if not found.</param>
    /// <returns>True if the entry was found; false otherwise.</returns>
    procedure GetTokenUrl(ICPartnerCode: Code[20]; var TokenUrl: Text[250]): Boolean
    var
        StoredValue: Text;
    begin
        if IsolatedStorage.Get(StorageKeyPrefixTok + ICPartnerCode + TokenUrlSuffixTok, DataScope::Company, StoredValue) then begin
            TokenUrl := CopyStr(StoredValue, 1, MaxStrLen(TokenUrl));
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Removes all stored OAuth2 credentials for the given IC partner from IsolatedStorage.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner whose credentials should be deleted.</param>
    procedure DeleteCredentials(ICPartnerCode: Code[20])
    begin
        if IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + SecretSuffixTok, DataScope::Company) then
            IsolatedStorage.Delete(StorageKeyPrefixTok + ICPartnerCode + SecretSuffixTok, DataScope::Company);
        if IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + TenantIdSuffixTok, DataScope::Company) then
            IsolatedStorage.Delete(StorageKeyPrefixTok + ICPartnerCode + TenantIdSuffixTok, DataScope::Company);
        if IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + ClientIdSuffixTok, DataScope::Company) then
            IsolatedStorage.Delete(StorageKeyPrefixTok + ICPartnerCode + ClientIdSuffixTok, DataScope::Company);
        if IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + TokenUrlSuffixTok, DataScope::Company) then
            IsolatedStorage.Delete(StorageKeyPrefixTok + ICPartnerCode + TokenUrlSuffixTok, DataScope::Company);
    end;

    /// <summary>
    /// Returns true when all four credential components (client secret, tenant ID,
    /// client ID, and token URL) are present in IsolatedStorage for the given partner.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner to check.</param>
    /// <returns>True if all credentials are configured; false if any component is missing.</returns>
    procedure HasCredentials(ICPartnerCode: Code[20]): Boolean
    begin
        exit(
            IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + SecretSuffixTok, DataScope::Company) and
            IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + TenantIdSuffixTok, DataScope::Company) and
            IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + ClientIdSuffixTok, DataScope::Company) and
            IsolatedStorage.Contains(StorageKeyPrefixTok + ICPartnerCode + TokenUrlSuffixTok, DataScope::Company)
        );
    end;
}
