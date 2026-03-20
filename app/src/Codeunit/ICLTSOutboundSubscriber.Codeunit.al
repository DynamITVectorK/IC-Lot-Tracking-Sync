/// <summary>
/// Subscribes to OnAfter* events raised by the standard IC Outbox management
/// codeunit and captures item-tracking data from outbound IC sales orders
/// into the ICLTS Tracking Buffer.
/// All logic is guarded by the MOD-01 module flag and all exceptions are caught
/// internally and written to the ICLTS Gap Log — never propagated to the BC call stack.
/// </summary>
codeunit 50304 "ICLTS Outbound Subscriber"
{
    Access = Internal;
    SingleInstance = false;

    var
        ICLTSSetup: Record "ICLTS Setup";
        ICLTSTrackingEngine: Codeunit "ICLTS Tracking Engine";
        ICLTSGapLogMgt: Codeunit "ICLTS Gap Log Mgt.";

    // ──────────────────────────────────────────────────────────────────────────
    // IC Outbox Mgt. — OnAfterSendICDocument
    // Fires after a sales document has been transmitted to the IC outbox.
    // ──────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Outbox Mgt.", 'OnAfterSendICDocument', '', false, false)]
    local procedure OnAfterSendICDocument(var ICOutboxTransaction: Record "IC Outbox Transaction"; var SalesHeader: Record "Sales Header")
    begin
        if not ICLTSSetup.IsModuleEnabled("ICLTS Module Code"::"MOD-01") then
            exit;

        if not TryCaptureOutboundTracking(SalesHeader, ICOutboxTransaction."IC Partner Code") then
            ICLTSGapLogMgt.LogError(
                "ICLTS Module Code"::"MOD-01",
                CopyStr(StrSubstNo('OnAfterSendICDocument SalesOrder=%1', SalesHeader."No."), 1, 250),
                CopyStr(GetLastErrorText(), 1, 2048));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // IC Outbox Mgt. — OnAfterCreateICOutboxSalesDocFromSalesHeader
    // Fires after IC outbox sales lines have been populated from the sales header.
    // Used as a fallback capture point when OnAfterSendICDocument is not raised.
    // ──────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Outbox Mgt.", 'OnAfterCreateICOutboxSalesDocFromSalesHeader', '', false, false)]
    local procedure OnAfterCreateICOutboxSalesDocFromSalesHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var SalesHeader: Record "Sales Header")
    var
        ICPartnerCode: Code[20];
    begin
        if not ICLTSSetup.IsModuleEnabled("ICLTS Module Code"::"MOD-01") then
            exit;

        ICPartnerCode := ICOutboxSalesHeader."IC Partner Code";
        if ICPartnerCode = '' then
            exit;

        if not TryCaptureOutboundTracking(SalesHeader, ICPartnerCode) then
            ICLTSGapLogMgt.LogError(
                "ICLTS Module Code"::"MOD-01",
                CopyStr(StrSubstNo('OnAfterCreateICOutboxSalesDocFromSalesHeader SalesOrder=%1', SalesHeader."No."), 1, 250),
                CopyStr(GetLastErrorText(), 1, 2048));
    end;

    [TryFunction]
    local procedure TryCaptureOutboundTracking(var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20])
    begin
        ICLTSTrackingEngine.CaptureOutboundTracking(SalesHeader, ICPartnerCode);
    end;
}
