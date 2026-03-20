/// <summary>
/// Identifies the functional modules available in the IC Lot Tracking Sync extension.
/// Used to independently enable or disable each synchronisation capability.
/// </summary>
enum 50300 "ICLTS Module Code"
{
    Extensible = false;

    /// <summary>Lot and serial number synchronisation across IC documents (MOD-01).</summary>
    value(0; "MOD-01")
    {
        Caption = 'Item Tracking Sync';
    }

    /// <summary>Item variant code synchronisation across IC documents (MOD-02).</summary>
    value(1; "MOD-02")
    {
        Caption = 'Variant Sync';
    }
}
