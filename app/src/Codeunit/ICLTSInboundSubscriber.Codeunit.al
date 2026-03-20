/// <summary>
/// Subscribes to OnAfter* events raised by the standard IC Inbox management
/// codeunit and applies buffered item-tracking data to inbound IC purchase orders.
/// All logic is guarded by the MOD-01 module flag and all exceptions are caught
/// internally and written to the ICLTS Gap Log — never propagated to the BC call stack.
/// </summary>
codeunit 50305 "ICLTS Inbound Subscriber"
{
    Access = Internal;
    SingleInstance = false;

    var
        ICLTSSetup: Record "ICLTS Setup";
        ICLTSTrackingEngine: Codeunit "ICLTS Tracking Engine";
        ICLTSGapLogMgt: Codeunit "ICLTS Gap Log Mgt.";

    // ──────────────────────────────────────────────────────────────────────────
    // IC Inbox Mgt. — OnAfterCreatePurchDocFromICInboxDoc
    // Fires after a purchase order has been created from an IC inbox transaction.
    // ──────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Inbox Mgt.", 'OnAfterCreatePurchDocFromICInboxDoc', '', false, false)]
    local procedure OnAfterCreatePurchDocFromICInboxDoc(var PurchaseHeader: Record "Purchase Header"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    var
        ICPartnerCode: Code[20];
        OutboundDocNo: Code[20];
    begin
        if not ICLTSSetup.IsModuleEnabled("ICLTS Module Code"::"MOD-01") then
            exit;

        ICPartnerCode := ICInboxPurchaseHeader."IC Partner Code";
        OutboundDocNo := ICInboxPurchaseHeader."IC Partner Reference";
        if (ICPartnerCode = '') or (OutboundDocNo = '') then
            exit;

        if not TryApplyInboundTracking(PurchaseHeader, ICPartnerCode, OutboundDocNo) then
            ICLTSGapLogMgt.LogError(
                "ICLTS Module Code"::"MOD-01",
                CopyStr(
                    StrSubstNo('OnAfterCreatePurchDocFromICInboxDoc PurchOrder=%1 ICPartner=%2',
                        PurchaseHeader."No.", ICPartnerCode),
                    1, 250),
                CopyStr(GetLastErrorText(), 1, 2048));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // IC Inbox Mgt. — OnAfterICInboxSalesDocToPurchOrder
    // Alternative event name used in some BC versions after the inbox sales document
    // is accepted and a purchase order is created.
    // ──────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Inbox Mgt.", 'OnAfterICInboxSalesDocToPurchOrder', '', false, false)]
    local procedure OnAfterICInboxSalesDocToPurchOrder(var PurchaseHeader: Record "Purchase Header"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    var
        ICPartnerCode: Code[20];
        OutboundDocNo: Code[20];
    begin
        if not ICLTSSetup.IsModuleEnabled("ICLTS Module Code"::"MOD-01") then
            exit;

        ICPartnerCode := ICInboxSalesHeader."IC Partner Code";
        OutboundDocNo := ICInboxSalesHeader."No.";
        if (ICPartnerCode = '') or (OutboundDocNo = '') then
            exit;

        if not TryApplyInboundTracking(PurchaseHeader, ICPartnerCode, OutboundDocNo) then
            ICLTSGapLogMgt.LogError(
                "ICLTS Module Code"::"MOD-01",
                CopyStr(
                    StrSubstNo('OnAfterICInboxSalesDocToPurchOrder PurchOrder=%1 ICPartner=%2',
                        PurchaseHeader."No.", ICPartnerCode),
                    1, 250),
                CopyStr(GetLastErrorText(), 1, 2048));
    end;

    [TryFunction]
    local procedure TryApplyInboundTracking(var PurchaseHeader: Record "Purchase Header"; ICPartnerCode: Code[20]; OutboundDocNo: Code[20])
    begin
        ICLTSTrackingEngine.ApplyInboundTracking(PurchaseHeader, ICPartnerCode, OutboundDocNo);
    end;
}
