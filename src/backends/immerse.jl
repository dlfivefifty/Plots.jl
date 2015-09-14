
# https://github.com/JuliaGraphics/Immerse.jl

immutable ImmersePackage <: PlottingPackage end

immerse!() = plotter!(:immerse)


function createImmerseFigure(d::Dict)
  println("Creating immerse figure: ", d)
  w,h = d[:size]
  figidx = Immerse.figure(; name = d[:windowtitle], width = w, height = h)
  Immerse.Figure(figidx)
end


# create a blank Gadfly.Plot object
function plot(pkg::ImmersePackage; kw...)
  d = Dict(kw)

  # create the underlying Gadfly.Plot object
  gplt = createGadflyPlotObject(d)

  # save both the Immerse.Figure and the Gadfly.Plot
  Plot((nothing,gplt), pkg, 0, d, Dict[])
end


# plot one data series
function plot!(::ImmersePackage, plt::Plot; kw...)
  d = Dict(kw)
  gplt = plt.o[2]
  addGadflySeries!(gplt, d)
  push!(plt.seriesargs, d)
  plt
end

function Base.display(::ImmersePackage, plt::Plot)
  println("disp1")

  fig, gplt = plt.o
  if fig == nothing
    fig = createImmerseFigure(plt.initargs)
    plt.o = (fig, gplt)
  end

  # display a new Figure object to force a redraw
  display(Immerse.Figure(fig.canvas, gplt))
end

# -------------------------------

function savepng(::ImmersePackage, plt::PlottingObject, fn::String;
                                    w = 6 * Immerse.inch,
                                    h = 4 * Immerse.inch)
  gctx = plt.o[2]
  Gadfly.draw(Gadfly.PNG(fn, w, h), gctx)
  nothing
end


# -------------------------------

# create the underlying object
function buildSubplotObject!(::ImmersePackage, subplt::Subplot)

  # create my Compose.Context grid by hstacking and vstacking the Gadfly.Plot objects
  i = 0
  rows = []
  for rowcnt in subplt.layout.rowcounts
    push!(rows, Gadfly.hstack([plt.o[2] for plt in subplt.plts[(1:rowcnt) + i]]...))
    i += rowcnt
  end
  gctx = Gadfly.vstack(rows...)

  # save this for later
  subplt.o = (nothing, gctx)
end


function Base.display(::ImmersePackage, subplt::Subplot)
  println("disp2")

  fig, gctx = subplt.o
  if fig == nothing
    fig = createImmerseFigure(subplt.initargs)
    subplt.o = (fig, gctx)
  end

  # fig.prepped = Gadfly.render_prepare(gctx)
  # # Render in the current state
  # fig.cc = render_finish(fig.prepped; dynamic=false)
  # # Render the figure
  # display(fig.canvas, fig)

  fig.cc = gctx
  # fig.prepped = nothing

  # display(fig.canvas, display(gctx))

  display(fig)
end