-- Read by included.xml's <Script file>: the mixin of its template, and the order the OnLoads ran in.
LabTestOrder = {}
LabTestMixin = {}

function LabTestMixin:OnLoad()
    table.insert(LabTestOrder, self.label or "?")
end
