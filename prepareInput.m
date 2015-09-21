function [out] = prepareInput(data)
    out = data;
    [out.detections, out.id, ~] ...
                      = out.allDetections.getCurrentDetections;
    out.detections    = manageDetections(out.detections);
    out.frame         = out.allDetections.cursor - 1;
    out.isempty       = isempty(out.allDetections);
    out.prediction    = [];
end