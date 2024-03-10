-- Register all Toolbar actions and intialize all UI stuff
function initUi()
    app.registerUi({["menu"] = "Update overlay", ["callback"] = "Update_overlay"})
end

local vips = require "vips" -- TODO pcall
local function load_pdf_image(fn, page, opacity, dpi)
    local inputImage = vips.Image.new_from_file(fn, {page=page, background=0, dpi=dpi})
    local r, g, b = table.unpack(inputImage:bandsplit())
    local img = r .. g .. b .. math.ceil(255*opacity)
    return img
end

local LAYER_NAME = "pdf_diff"
function Update_overlay()
    local doc = app.getDocumentStructure()
    local fn = doc.pdfBackgroundFilename .. ".bak"
    for i,p in ipairs(doc.pages) do
        if p.pdfBackgroundPageNo ~= 0 then
            -- goto page
            app.setCurrentPage(i)
            local layer_removed = false
            for j,l in ipairs(p.layers) do
                if l.name == LAYER_NAME then
                    app.setCurrentLayer(j, false)
                    app.layerAction("ACTION_DELETE_LAYER")
                    layer_removed = true
                end
            end
            -- create new layer
            app.layerAction("ACTION_NEW_LAYER")
            app.setCurrentLayerName(LAYER_NAME)
            local idx = #p.layers + 1 + (layer_removed and -1 or 0)
            app.setCurrentLayer(idx, false)


            local err = app.addImages(
                {
                    images =
                        {{
                            data=load_pdf_image(fn, p.pdfBackgroundPageNo-1, 0.5, 300):write_to_buffer(".png"),
                            x=0,
                            y=0,
                            maxHeight=math.floor(p.pageHeight)
                        }},
                    allowUndoRedoAction = "grouped"
                }
            )
            if err then
                app.openDialog("Error inserting image for page " .. i, {"Ok"}, "", true)
            end
        end
    end
end
