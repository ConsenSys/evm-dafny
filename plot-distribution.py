#! python3

import argparse
from matplotlib import table
from quantiphy import Quantity

parser = argparse.ArgumentParser()
parser.add_argument('paths', nargs='+')
parser.add_argument("-v", "--verbose", action="count", default=0)
parser.add_argument("-p", "--recreate-pickle",action="store_true")
parser.add_argument("-n", "--nbins", default=50)
#parser.add_argument("-y", "--ylog",action="store_true")
parser.add_argument("-d", "--delta", type=int, default=10, help="The delta maxRC-minRC (as a % of max) over which a plot might be interesting")
parser.add_argument("-i", "--ignore", action='append', default=[], help="DisplayNames with these substrings will be ignored")
parser.add_argument("-t", "--top", type=int, default=5, help="Plot only the first N at the top of the list")
parser.add_argument("-l", "--limitRC", type=Quantity, default=None, help="RCs over this limit will be considered failure markers")

args = parser.parse_args()


import json
import logging as log
from math import inf
import os
import pickle
from time import sleep
import numpy as np
import pandas as pd
import re
from datetime import datetime as dt, timedelta as td

from quantiphy import Quantity


def cleanDisplayName(dn:str) -> str:
    new = dn.replace("(well-formedness)","") # WF is almost everywhere, so omit it; better just mention anything non-WF
    new = new.replace("(correctness)","[C]")
    new = re.sub(r"\(assertion batch (\d+)\)",r"AB\1", new)
    return new.strip()

class Details:
    def __init__(self):
        self.RC: list[int]= []
        self.fails = []
    RC: list[int]
    RC_max: int
    RC_min: int
    line: int = None
    col: int = None
    description: str = None
    randomSeed: int = None
    RC_delta: int
    fails: list[int]



def readJSON(fullpath) -> int:  #reads 1 file, returns number of entries created
    # We want entries like: Precompiled.CallModExp WF ABx : [usages],Line,Col,Description,Failed
    entries = 0
    global results
    with open(fullpath) as jsonfile:
        verificationResults = json.load(jsonfile)["verificationResults"]
    log.debug(f"{fullpath}: {len(verificationResults)} verificationResults")

    # A JSON verification log contains a list of verificationResults
    # Each of vR corresponds to a function or method
    # and contains its Display Name, overall Resource Count, verification outcome and the Assertion Batches (vcResults)
    #   Each AB contains its number (vcNum), outcome, Resource Count, and a list of assertions
    # If "isolating assertions" was NOT used, then the AB list in a vR will contain only 1 AB
    #   1 vR = 1 AB = 1*(multiple assertions); we ignore them for plotting
    #       The AB contains the details we want; we ignore the individual assertions
    # If "isolating assertions" was used, then
    #   1 vR = n AB = n*(1 assertion)
    #       Each AB contains details we want; we store the assertion locations
    #
    # Recap: if "isolating assertions" was NOT used, then the AB number is always 1, so no need to add it to our DN
    # and its entry only contains the list of RCs, not anything deeper
    # But if "isolating assertions" was used, then each DN contains an "AB x";
    # and each DN+AB's entry contains not only list of RCs, but also location

    mode_IA = None  # Isolate Assertions. Guess the mode to check if it stays coherent.
    for vr in verificationResults:
        display_name = cleanDisplayName(vr["name"])
        assert vr["outcome"] in ["Correct", "Errors", "OutOfResource"], f"{vr["name"]} has unknown outcome: {vr["outcome"]=}"

        # Without "isolating assertions", there is only 1 vcr per vr
        # Curiously, with IA, there is always (?) an extra empty assertion in each AB, so with IA the minimum is 2 assertions per AB

        if mode_IA == None:
            mode_IA = (len(vr['vcResults']) > 1)

        assert mode_IA == (len(vr['vcResults']) != 1), f"It looked like 'isolating-assertions'=={mode_IA}, and yet there's {len(vr['vcResults'])} ABs for {display_name}"

        # We will store only the vcr's RC in each DN
        # but check that the vr's RC equals the sum of the vcrs.
        vcrs_RC = []
        vr_RC = vr["resourceCount"]

        vr_randomseed = None
        for vcr in vr['vcResults']:
            if vr_randomseed == None:
                vr_randomseed = vcr["randomSeed"]
            else:
                assert vr_randomseed == vcr["randomSeed"]

            #assert vcr['outcome'] == "Valid", f"{vr["name"]} has vcResult.outcome == {vr["outcome"]}, stopping"
            if mode_IA:
                # There's multiple ABs. Each AB contains a single assertion
                display_name_AB: str = display_name + f" AB{vcr["vcNum"]}"
                det: Details = results.get(display_name_AB, Details())
                if len(vcr['assertions']) == 0:
                    assert vcr['vcNum'] == 1 #only seems to happen in the first one
                    # Ensure that it's empty every time it appears
                    assert det.line == None
                    assert det.col == None
                    assert det.description == None
                else:
                    assert len(vcr['assertions']) == 1, f"{display_name_AB} contains {len(vcr['assertions'])} assertions, expected only 1 because we're in IA mode!"
                    a = vcr['assertions'][0]
                    if det.line != None:
                        # Just double-check that everything stays consistent with previous appearances
                        assert det.line == a['line']
                        assert det.col == a['col']
                        assert det.description == a['description']
                    else:
                        det.line = a['line']
                        det.col = a['col']
                        det.description = a['description']

            else:
                # A single AB with all the assertions. We don't want that much detail for plotting.
                display_name_AB = display_name
                det: Details = results.get(display_name_AB, Details())
                pass

            vcr_RC = vcr['resourceCount']
            vcrs_RC.append(vcr_RC)
            det.randomSeed = vcr['randomSeed']
            if vcr["outcome"] != "Valid" :
                assert vcr["outcome"] in ["OutOfResource","Invalid"], f"{display_name_AB}.outcome == {vcr["outcome"]}: unexpected!"
                assert vr["outcome"] in ["OutOfResource","Errors"], f"{display_name}.outcome == {vr["outcome"]}: unexpected!"
                det.fails.append(vcr_RC)
            else: # vcr Valid
                det.RC.append(vcr_RC)
            results[display_name_AB] = det
            entries += 1
        assert sum(vcrs_RC) == vr_RC, f"{display_name}.RC={vr_RC}, but the sum of the vcrs' RCs is {sum(vcrs_RC)} "
    return entries

def smag(i) -> str:
    return f"{Quantity(i):.3}"


numeric_level = log.WARNING - args.verbose * 10
log.basicConfig(level=numeric_level,format='%(asctime)s-%(levelname)s:%(message)s',datefmt='%H:%M:%S')


results: dict[str, Details] = {}    # DisplayName (ABn) : details
files = 0
entries = 0
# to be un/pickled: [files, entries, results]

t0 = dt.now()
plotfilepath = "".join(args.paths)+".html"
picklefilepath = "".join(args.paths)+"v2.pickle"
pickle_contents = []
if os.path.isfile(picklefilepath) and not args.recreate_pickle:
    with open(picklefilepath, 'rb') as pf:
        [files, entries, results] = pickle.load(pf)
    print(f"Loaded pickle: {files} files, {entries} rows in {(dt.now()-t0)/td(seconds=1)}")
else:

    for p in args.paths:
        # os.walk doesn't accept files, only dirs; so we need to process single files separately
        log.debug(f"root {p}")
        if os.path.isfile(p):
            entries_read = readJSON(p)
            if entries_read == 0:
                print(f"no rows in {p}")
                exit(1)
            files +=1
            entries += entries_read
            continue
        files_before_root = files
        for dirpath, dirnames, dirfiles in os.walk(p):
            files_before = files
            for f in dirfiles:
                if not ".json" in f:
                    continue
                files +=1
                fullpath = os.path.join(dirpath, f)
                log.debug(f"file {files}: {fullpath}")
                #rows_before = entries
                entries_read = readJSON(fullpath)
                if entries_read == 0:
                    print(f"no files found in {p}")
                    exit(1)
                entries += entries_read

        if files_before_root == files:
            print(f"no files found in {p}")
            exit(1)


    print(f"Processed {files} files, {entries} rows in {(dt.now()-t0)/td(seconds=1)}")
    #print(results)

    with open(picklefilepath, "wb") as pf:
        pickle.dump([files, entries, results], pf)




log.debug("Selecting traces")
# Decide which results look interesting, taking into account that they all will be plotted together

#traces_selected = []
#labels_selected = []
maxRC = -inf
minRC = inf

for k,v in results.items():
    for ig in args.ignore:
        if ig in k:
            continue
    minRC_entry = min(v.RC)
    minRC = min(minRC, minRC_entry)
    maxRC_entry = max(v.RC)
    maxRC = max(maxRC, maxRC_entry)
    if args.limitRC != None:
            # if there was a limit, any resource count over the limit should be in the fails, not in the RCs
            assert maxRC_entry < args.limitRC, f"{args.limitRC=} but {maxRC_entry=}"
            #assert v.fails == [] or min(v.fails) > args.limitRC,
            if v.fails != [] and min(v.fails) < args.limitRC:
                log.warning(f"{args.limitRC=} but min failed for {k} is smaller {min(v.fails)=}")
    # Calculate the % difference between max and min
    delta = (maxRC_entry-minRC_entry)/maxRC_entry 
    line = f"{k:40} {len(v.RC):>10} {smag(minRC_entry):>8}    {smag(maxRC_entry):>6} {delta:>8.2%}"
    log.debug(line)
    # if len(v.fails) == 0 and delta < args.delta/100:
    #     # uninteresting results won't even store a delta
    #     continue

    results[k].RC_max = maxRC_entry
    results[k].RC_min = minRC_entry
    results[k].RC_delta = delta
    #print(f"{line}")
    #traces_selected.append(v)
    #labels_selected.append(k)

#sort the dictionary of results by the delta; high delta == high interest
results = {k:v for k,v in sorted(results.items(), reverse=True, key=lambda item: getattr(item[1],'RC_delta',0))}
# but failed results are even more interesting
results = {k:v for k,v in sorted(results.items(), reverse=True, key=lambda item: getattr(item[1],'fails'))}


if len(next(iter(results.items()))[1].fails) > 0 and args.limitRC==None:
    log.warning(f"There are 'failed' results, but no limitRC was given!")

# Plot legends can't be sorted, so add the sorted index to the beginning of each DN
# results2 = {f'{i+1} {k}':v for i,(k,v) in enumerate(results.items())}
# results = results2

# We have the interesting DNs, but when plotting all histograms together, the bin distribution might cause some DNs to fall into a single bin
# So let's remove those from the plots
# For that, we need to calculate all the histograms
#table = ""
table_df = pd.DataFrame( columns=["Element", "minRC", "maxRC", "delta", "success", "fails", "plotted"])
#table += f"{'Display Name':40} {'Datapoints':>10} {'minRC':>8}    {'maxRC':>6} {'  diff':>8} {'fails':>6}\n"
#table += f"{'============':40} {'==========':>10} {'=====':>8}    {'=====':>6} {'======':>8} {'=====':>6}\n"
bins = np.linspace(minRC,maxRC, num=args.nbins+1)
# add a  bin for fails, wide so that it stands out
bin_width = bins[1]-bins[0]
bins_extension = bins[-1] + [1 * bin_width, 3 * bin_width]
# maxX = bins[-1] + 4 * bin_width
bins_with_fails = np.append(bins,bins_extension)


#hist_dict = {}
labels_plotted = []
hist_df = pd.DataFrame()
bh = 0.5 * (bins_with_fails[:-1] + bins_with_fails[1:])
hist_df["bins"] = bh
#hist_df["zeros"] = len(bins[:-1]) * [0]
hist_df = hist_df.reindex()
# the results dict is sorted by delta; to keep that order we need to traverse the dict, not the list of labs_selected
for n,dn in enumerate(results.keys()):
    # if n == args.top:
    #     break
    d = results[dn]
    #delta = getattr(d,'RC_delta',0)
    # if len(d.fails) == 0 and delta < args.delta/100:
    #     break #because it's sorted and we ran out of interesting cases
    
    #failstr = len(d.fails) if len(d.fails)>0 else ""
    #line = f"{dn:40} {len(d.RC):>10} {smag(d.RC_min):>8}    {smag(d.RC_max):>6} {d.RC_delta:>8.2%} {failstr:>6}"

    counts, _ = np.histogram(d.RC,bins=bins)
    counts = np.append(counts,[0,len(d.fails)])

    # remove plots that would span less than 3 bins
    nonempty_bins = []
    for i,c in enumerate(counts):
        if c != 0:
            nonempty_bins.append(i)
    plotted = (n < args.top) \
                            and ((nonempty_bins[-1]-nonempty_bins[0] > 3) \
                                or (len(d.fails) > 0))
    table_df.loc[n+1] = {
        "Element": dn,
        "success": len(d.RC),
        "minRC": smag(d.RC_min),
        "maxRC": smag(d.RC_max),
        "delta": f"{d.RC_delta:>8.2%}",
        "fails": len(d.fails),
        "plotted": plotted
    }

    if plotted:
        #hist_dict[dn] = counts
        labels_plotted.append(dn)
        hist_df[dn] = counts
        with np.errstate(divide='ignore'): # to silence the errors because of log of 0 values
            hist_df[dn+"_log"] = np.log10(counts)

#print(table)
print(table_df)

# fails_df = table_df[["Element","fails"]][table_df['plotted']==True]
# fails_df["Log(Count)"]=np.log10(fails_df["fails"])





# HOLOVIEWS


import holoviews as hv
import hvplot
from hvplot import hvPlot
from holoviews import opts

hv.extension('bokeh')
renderer = hv.renderer('bokeh')

# log.debug("creating dataframe")
# d = {k:v for k,v in zip(results.keys(), map(lambda v: v.RC, results.values()))}
# df = pd.DataFrame(d)
# df = df.reset_index() # adds an index column, makes life easier with plotting libs

# log.debug("hvplot")
# histplots_dict_lin = {
#     l: hv.Histogram((bins, hist_dict[l])).redim(x="RC").opts(autorange='y',ylim=(0,None), xlim=(bins[0],bins[-1]),padding=(0, (0, 0.1)))
#         for l in hist_dict.keys()
#     }
# hists_lin = hv.NdOverlay(histplots_dict_lin)#, kdims='Elements')
# hists_lin.opts(
#     opts.Histogram(alpha=0.9, responsive=True, height=500,  tools=['hover'],autorange='y',show_legend=True)
#     #,logy=True # histograms with logY have been broken in bokeh for years: https://github.com/holoviz/holoviews/issues/2591
#     )

histplots_dict = {}
jitter = (bin_width)/len(hist_df)/3
for i,l in enumerate(labels_plotted):
    h = hv.Histogram((bins_with_fails+i*jitter,hist_df[l+"_log"],hist_df[l]),kdims=["RC"],vdims=["Log(Count)", "Count"]).opts(
        autorange='y',ylim=(0,None), xlim=(bins_with_fails[0],bins_with_fails[-1]),padding=(0, (0, 0.1))
        )
    histplots_dict[l] = h

#hist_dummylogy= hv.Histogram((hist_df["bins"],hist_df["zeros"]),kdims=["RC"]).opts(autorange='y',ylim=(0,None), xlim=(bins[0],bins[-1]),padding=(0, (0, 0.1)))
#histplots_dict["dummy"] = hist_dummylogy

hists = hv.NdOverlay(histplots_dict)#, kdims='Elements')
hists.opts(
    opts.Histogram(alpha=0.9, responsive=True, height=500,  tools=['hover'],autorange='y',show_legend=True, muted=True)
    #,logy=True # histograms with logY have been broken in bokeh for years: https://github.com/holoviz/holoviews/issues/2591
    )

# fails = hv.NdOverlay(failplots_dict)
# fails.opts(
#     opts.Histogram(alpha=0.9, responsive=True, height=2000,  tools=['hover'],autorange='y',show_legend=True, muted=True)
#     #,logy=True # histograms with logY have been broken in bokeh for years: https://github.com/holoviz/holoviews/issues/2591
#     )




nlabs = len(labels_plotted)
spikes_dict = {}
for i,dn in enumerate(labels_plotted):
    x= results[dn].RC
    if results[dn].fails != []:
        x.append(bins_with_fails[-1])
    y = [dn]*len(x) # so that it'll appear in the hover tool
    spikes_dict[dn] = hv.Spikes((x,y),kdims="RC").opts(position=i,tools=['hover'])
spikes = hv.NdOverlay(spikes_dict).opts(yticks=[((i+1)-0.5, list(spikes_dict.keys())[i]) for i in range(nlabs)])
spikes.opts(
    opts.Spikes(spike_length=1,line_alpha=1,responsive=True, height=50+nlabs*20,color=hv.Cycle(),ylim=(0,nlabs),autorange=None,tools=['hover'],yaxis='right'),
    opts.NdOverlay(show_legend=False,click_policy='mute',autorange=None,ylim=(0,nlabs),tools=['hover']),
    #opts.NdOverlay(shared_axes=True, shared_datasource=True,show_legend=False)
    )

table_plot = hv.Table(table_df.drop(columns=['plotted']),kdims="Element")

plot = hists + spikes + table_plot #+ hist #+ violin
plot.cols(1)

from bokeh.models import NumeralTickFormatter
from bokeh.util.compiler import TypeScript
class MyFormatter(NumeralTickFormatter):
    __implementation__ = TypeScript("""
import {NumeralTickFormatter} from "models/formatters/numeral_tick_formatter"

export class MyFormatter extends NumeralTickFormatter {
  FAIL_MIN=""" + str(int(maxRC)) + """

  doFormat(ticks: number[], _opts: {loc: number}): string[] {
    const formatted = []
    const ticks2 = super.doFormat(ticks, _opts)
    for (let i = 0; i < ticks.length; i++) {
      if (ticks[i] < this.FAIL_MIN) {
        formatted.push(ticks2[i])
      } else {
        formatted.push('FAILED')
      }
    }
    return formatted
  }
}
""")

mf = MyFormatter(format="0.0a")

plot.opts(
#     #opts.Violin(tools=['box_select','lasso_select']),
#     #opts.Histogram(responsive=True, height=500, width=1000),
    # opts.Layout(sizing_mode="scale_both", shared_axes=True, sync_legends=True, shared_datasource=True)
    opts.NdOverlay(click_policy='mute',autorange='y',xformatter=mf,legend_position="right")
)
plot.opts(shared_axes=True)







try:
    os.remove(plotfilepath)
except:
    pass

#renderer.save(plot, 'plot')
hv.save(plot, plotfilepath)
#hvplot.show(plot)
# from bokeh.resources import INLINE
#plot.save(plotfilepath)#, resources=INLINE)

print(f"Created file {plotfilepath}")
os.system(f"open {plotfilepath}")

#webbrowser.open('plot.html')

# ls = hv.link_selections.instance()
# lplot = ls(plot)
# hv.save(lplot, 'lplot.html')
# os.system("open lplot.html")



