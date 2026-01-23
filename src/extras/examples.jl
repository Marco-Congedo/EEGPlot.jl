#=
 This test runs several plots (in static mode) to make sure
 the function eegplot runs smoothly.
 Install Eegle and CairoMakie for running it
=#

using Eegle, EEGPlot
using CairoMakie

# from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

# default settings
eegplot(X, sr, sensors)

# Without providing labels for X
eegplot(X, sr)

# Two panels; Y must have the same # of samples as X
eegplot(X, sr, sensors; Y=X)

# Overlay; overlay must have the same number of samples and of channels as X
eegplot(X, sr, sensors; overlay=X)

# Both overlay and two panels
eegplot(X, sr, sensors; overlay=X, Y=X)

# Change pixels per second (time-constnat)
eegplot(X, sr, sensors; px_per_sec = 300)

# Notice that the data is plotted with the same time constant
# regardless the sampling rate

using Eegle
eegplot(resample(X, sr, 2), 256, sensors; px_per_sec = 300)

# Change titles and colors
eegplot(X, sr, sensors; Y=X, 
    X_title="This the title for the upper panel",
    X_color=:blue,
    Y_title="This the title for the lower panel",
    Y_color=:darkviolet,
    )


# start plotting from second 2    
heegplot(X, sr, sensors; start_pos=sr*2)

# start plotting from an arbitrary sample (345)
eegplot(X, sr, sensors; start_pos=345)

# plot from sample 345 to sample 345+sr*2 (2s)
eegplot(X, sr, sensors; start_pos=129, win_length = sr*4)







